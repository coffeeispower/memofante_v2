import { type ServerWebSocket } from "bun";
import { pipe, Schema } from "effect";
import type { Utc } from "effect/DateTime";
import { ParseError } from "effect/ParseResult";

// Mapa dos clientes agrupados por syncCode (vários dispositivos podem usar o mesmo código)
const clients: Map<string, Set<ServerWebSocket<undefined>>> = new Map();

// Guarda o syncCode associado a cada websocket
const clientSyncCode: WeakMap<ServerWebSocket, string> = new WeakMap();
type LocalState ={ words: readonly (typeof DiscoveredWord.Type)[], transactions: readonly Transaction.Types.Transaction[] };
// Dados de sincronização enviados pelos clientes (para cada syncCode, acumulamos os estados locais)
const syncData: Map<string, LocalState[]> = new Map();

export const DiscoveredWord = Schema.Struct({
  entryNumber: Schema.Int,
  failedMeaningReviews: Schema.Int,
  failedReadingReviews: Schema.Int,
  successMeaningReviews: Schema.Int,
  successReadingReviews: Schema.Int,
  lastReadingReview: Schema.NullOr(Schema.DateTimeUtc),
  lastMeaningReview: Schema.NullOr(Schema.DateTimeUtc)
});

// Acrescentei o campo "date" em ambas as transações para poder ordenar
namespace Transaction {
  export const AddWordTransaction = Schema.Struct({
    type: Schema.Literal("add_word"),
    word: DiscoveredWord,
    date: Schema.DateTimeUtc
  });

  export const RemoveWordTransaction = Schema.Struct({
    type: Schema.Literal("remove_word"),
    entryNumber: Schema.Int,
    date: Schema.DateTimeUtc
  });

  export const Transaction = Schema.Union(AddWordTransaction, RemoveWordTransaction);
  export namespace Types {
    export type AddWordTransaction = typeof AddWordTransaction.Type;
    export type RemoveWordTransaction = typeof RemoveWordTransaction.Type;
    export type Transaction = typeof Transaction.Type;
  }
}

// Pacotes enviados pelo cliente
namespace Client {
  export const UseSyncCodePacket = Schema.Struct({
    type: Schema.Literal("use_sync_code"),
    syncCode: Schema.String
  });
  export const SyncRequestPacket = Schema.Struct({
    type: Schema.Literal("request_sync")
  });
  // Pacote que contém o estado local (lista e transações)
  export const LocalStatePacket = Schema.Struct({
    type: Schema.Literal("local_state"),
    words: Schema.Array(DiscoveredWord),
    transactions: Schema.Array(Transaction.Transaction)
  });
  export const Packet = Schema.Union(UseSyncCodePacket, SyncRequestPacket, LocalStatePacket);
  export namespace Types {
    export type UseSyncCodePacket = typeof UseSyncCodePacket.Type;
    export type SyncRequestPacket = typeof SyncRequestPacket.Type;
    export type LocalStatePacket = typeof LocalStatePacket.Type;
    export type BoundPacket = typeof Packet.Type;
  }
}

// Pacotes enviados pelo servidor
namespace Server {
  export const SyncCompletePacket = Schema.Struct({
    type: Schema.Literal("sync_complete"),
    finalWords: Schema.Array(DiscoveredWord)
  });
  // Novo pacote para solicitar que os clientes enviem o estado local
  export const RequestLocalStatePacket = Schema.Struct({
    type: Schema.Literal("request_local_state")
  });
  export namespace Types {
    export type SyncCompletePacket = typeof SyncCompletePacket.Type;
    export type RequestLocalStatePacket = typeof RequestLocalStatePacket.Type;
  }
}
// Função auxiliar para comparar duas datas (do tipo Schema.DateTimeUtc)
function chooseLaterDate(a: Utc | null, b: Utc | null) {
  if (!a) return b;
  if (!b) return a;
  return a.epochMillis >= b.epochMillis ? a : b;
}

// Função auxiliar para mesclar duas palavras descobertas com o mesmo entryNumber
function mergeDiscoveredWord(
  wordA: typeof DiscoveredWord.Type,
  wordB: typeof DiscoveredWord.Type
): typeof DiscoveredWord.Type {
  return {
    entryNumber: wordA.entryNumber, // Ambos são iguais
    failedMeaningReviews: Math.max(wordA.failedMeaningReviews, wordB.failedMeaningReviews),
    failedReadingReviews: Math.max(wordA.failedReadingReviews, wordB.failedReadingReviews),
    successMeaningReviews: Math.max(wordA.successMeaningReviews, wordB.successMeaningReviews),
    successReadingReviews: Math.max(wordA.successReadingReviews, wordB.successReadingReviews),
    lastReadingReview: chooseLaterDate(wordA.lastReadingReview, wordB.lastReadingReview),
    lastMeaningReview: chooseLaterDate(wordA.lastMeaningReview, wordB.lastMeaningReview)
  };
}

function mergeSyncData(
  localStates: readonly LocalState[]
): readonly (typeof DiscoveredWord.Type)[] {
  // 1. Combina todas as palavras de todos os estados, mesclando os dados de review
  const allWordsMap: Map<number, typeof DiscoveredWord.Type> = new Map();
  for (const state of localStates) {
    for (const word of state.words) {
      if (allWordsMap.has(word.entryNumber)) {
        const existing = allWordsMap.get(word.entryNumber)!;
        allWordsMap.set(word.entryNumber, mergeDiscoveredWord(existing, word));
      } else {
        allWordsMap.set(word.entryNumber, word);
      }
    }
  }

  // 2. Junta todas as transações e ordena por data (do mais antigo para o mais recente)
  let allTransactions: Array<Transaction.Types.Transaction> = [];
  for (const state of localStates) {
    allTransactions = allTransactions.concat(state.transactions);
  }
  allTransactions.sort((a, b) => a.date.epochMillis - b.date.epochMillis);

  // 3. Deriva a "lista original" removendo as palavras mencionadas em transações
  const mentioned: Set<number> = new Set();
  for (const tx of allTransactions) {
    if (tx.type === "add_word") {
      mentioned.add(tx.word.entryNumber);
    } else if (tx.type === "remove_word") {
      mentioned.add(tx.entryNumber);
    }
  }
  for (const entryNumber of mentioned) {
    allWordsMap.delete(entryNumber);
  }
  // Cria a baseList a partir do mapa restante
  const baseList: Map<number, typeof DiscoveredWord.Type> = new Map(allWordsMap);

  // 4. Aplica as transações mescladas sobre a baseList, mesclando também as estatísticas
  for (const tx of allTransactions) {
    if (tx.type === "add_word") {
      if (baseList.has(tx.word.entryNumber)) {
        // Mescla os dados de review entre o que já existe e o que vem da transação
        const existing = baseList.get(tx.word.entryNumber)!;
        baseList.set(tx.word.entryNumber, mergeDiscoveredWord(existing, tx.word));
      } else {
        baseList.set(tx.word.entryNumber, tx.word);
      }
    } else if (tx.type === "remove_word") {
      baseList.delete(tx.entryNumber);
    }
  }

  // 5. O estado final é a lista resultante
  return Array.from(baseList.values());
}


Bun.serve<undefined, never>({
  fetch(req, server) {
    // upgrade the request to a WebSocket
    if (server.upgrade(req)) {
      return; // do not return a Response
    }
    return new Response("WebSocket server running", { status: 200 });
  },
  websocket: {
    open(ws) {
      // Inicialização, se necessário.
    },
    message(ws, messageString) {
      try {
        const message = pipe(
          messageString,
          String,
          JSON.parse,
          Schema.decodeUnknownSync(Client.Packet)
        ) as Client.Types.BoundPacket;
        console.log(message);
        console.log("<------ IN");
        switch (message.type) {
          case "use_sync_code": {
            // Regista o cliente com o syncCode
            clientSyncCode.set(ws, message.syncCode);
            if (!clients.has(message.syncCode)) {
              clients.set(message.syncCode, new Set());
            }
            clients.get(message.syncCode)!.add(ws);
            break;
          }
          case "request_sync": {
            // Quando um cliente solicita sincronização, envia um pacote "request_local_state" para todos os clientes com o mesmo syncCode
            const syncCode = clientSyncCode.get(ws);
            if (!syncCode) {
              console.error("Cliente não registado com syncCode.");
              return;
            }
            // Limpa dados antigos de sincronização para este syncCode
            syncData.delete(syncCode);
            const requestPayload = JSON.stringify(Schema.encodeSync(Server.RequestLocalStatePacket)({ type: "request_local_state" }));

            console.log(JSON.parse(requestPayload));
            console.log("------> OUT");
            for (const client of clients.get(syncCode)!) {
              client.send(requestPayload);
            }
            break;
          }
          case "local_state": {
            // Recebe o estado local de um cliente
            const syncCode = clientSyncCode.get(ws);
            if (!syncCode) {
              console.error("Cliente não registado com syncCode.");
              return;
            }
            if (!syncData.has(syncCode)) {
              syncData.set(syncCode, []);
            }
            syncData.get(syncCode)!.push({
              words: message.words,
              transactions: message.transactions
            });

            // Verifica se já recebemos os dados de todos os clientes para este syncCode
            calculateAndSendFinalStateIfFinished(syncCode);
            break;
          }
        }
      } catch(e: any) {
        console.error(e.message);
        ws.close();
      }
    },
    close(ws, code, reason) {
      // Remove o cliente desconectado
      const syncCode = clientSyncCode.get(ws);
      if (syncCode && clients.has(syncCode)) {
        clients.get(syncCode)!.delete(ws);
        if (clients.get(syncCode)!.size === 0) {
          clients.delete(syncCode);
          syncData.delete(syncCode);
        }
        calculateAndSendFinalStateIfFinished(syncCode);
      }
    },
  },
});
function calculateAndSendFinalStateIfFinished(syncCode: string) {
  if(!syncData.has(syncCode)) return;
  const expectedCount = clients.get(syncCode)?.size ?? 0;
  const receivedCount = syncData.get(syncCode)!.length;
  if (receivedCount >= expectedCount && expectedCount > 0) {
    // Calcula o estado final
    const finalWords = mergeSyncData(syncData.get(syncCode)!);
    // Envia o estado final para todos os clientes registados com este syncCode
    const payload = JSON.stringify(Schema.encodeSync(Server.SyncCompletePacket)({ type: "sync_complete", finalWords }));

    console.log(JSON.parse(payload));
    console.log("------> OUT");
    for (const client of clients.get(syncCode)!) {
      client.send(payload);
    }
    // Limpa os dados de sincronização para este syncCode
    syncData.delete(syncCode);
  }
}

