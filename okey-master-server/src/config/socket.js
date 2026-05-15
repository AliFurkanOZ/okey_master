const { Server } = require('socket.io');
const crypto = require('crypto');

const waitingPlayers = []; // { socketId, nickname, type }
const rooms = {}; // { roomId: { players: [], gameState: {} } }

/**
 * Sunucu tarafında 48 taşlık deste oluştur ve Fisher-Yates ile karıştır
 */
function createAndShuffleDeck() {
  const colors = ['siyah', 'mavi', 'kirmizi', 'sari'];
  const deck = [];

  for (const color of colors) {
    for (let i = 1; i <= 12; i++) {
      deck.push({
        id: `${color}_${i}_${crypto.randomBytes(4).toString('hex')}`,
        value: i,
        color: color,
        isRevealed: false,
      });
    }
  }

  // Fisher-Yates Shuffle (kriptografik güvenli)
  for (let i = deck.length - 1; i > 0; i--) {
    const j = crypto.randomInt(0, i + 1);
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }

  return deck;
}

/**
 * Desteyi iki oyuncuya dağıt (6 sütun × 4 taş = 24 taş her oyuncuya)
 * Ortadaki taş: Joker (sahte okey) ile başlar
 */
function distributeCards(deck) {
  const player1Cols = [];
  const player2Cols = [];

  let deckIndex = 0;
  for (let col = 0; col < 6; col++) {
    const p1Col = [];
    for (let row = 0; row < 4; row++) {
      p1Col.push(deck[deckIndex++]);
    }
    player1Cols.push(p1Col);
  }

  for (let col = 0; col < 6; col++) {
    const p2Col = [];
    for (let row = 0; row < 4; row++) {
      p2Col.push(deck[deckIndex++]);
    }
    player2Cols.push(p2Col);
  }

  const centerStone = {
    id: 'joker',
    value: 0,
    color: 'joker',
    isRevealed: true,
  };

  return { player1Cols, player2Cols, centerStone };
}

module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log('[Socket] Yeni bağlantı:', socket.id);

    socket.on('join_queue', ({ nickname, type }) => {
      console.log(`[Socket] ${nickname} sıraya girdi (${type})`);
      
      // Aynı tipte bekleyen oyuncu var mı?
      const matchIndex = waitingPlayers.findIndex(p => p.type === type && p.socketId !== socket.id);
      
      if (matchIndex !== -1) {
        const opponent = waitingPlayers.splice(matchIndex, 1)[0];
        const roomId = `room_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        socket.join(roomId);
        io.sockets.sockets.get(opponent.socketId)?.join(roomId);
        
        const players = [
          { id: socket.id, nickname: nickname },
          { id: opponent.socketId, nickname: opponent.nickname }
        ];

        // Rastgele kimin başlayacağını seç
        const firstPlayerIdx = Math.random() < 0.5 ? 0 : 1;

        // ============ SUNUCUDA DESTE OLUŞTUR VE DAĞIT ============
        const deck = createAndShuffleDeck();
        const { player1Cols, player2Cols, centerStone } = distributeCards(deck);

        // Oyun durumunu sunucuda sakla
        rooms[roomId] = {
          roomId,
          players,
          gameState: {
            player1Cols, // players[0]'ın taşları
            player2Cols, // players[1]'in taşları
            centerStone,
          }
        };

        console.log(`[Socket] Maç başladı: ${roomId} (${nickname} vs ${opponent.nickname})`);
        console.log(`[Socket] Deste dağıtıldı. Ortadaki taş: ${centerStone.color}_${centerStone.value}`);

        // ============ HER OYUNCUYA KENDİ PERSPEKTİFİNDEN GÖNDERGame State ============
        
        // Oyuncu 1'e (socket — mevcut bağlanan) gönder
        io.to(socket.id).emit('game_start', {
          roomId,
          players,
          firstTurn: players[firstPlayerIdx].id,
          gameState: {
            playerStones: player1Cols,
            opponentStones: player2Cols,
            centerStone: centerStone,
          }
        });

        // Oyuncu 2'ye (opponent) gönder (perspektif ters)
        io.to(opponent.socketId).emit('game_start', {
          roomId,
          players,
          firstTurn: players[firstPlayerIdx].id,
          gameState: {
            playerStones: player2Cols,
            opponentStones: player1Cols,
            centerStone: centerStone,
          }
        });

      } else {
        waitingPlayers.push({ socketId: socket.id, nickname, type });
      }
    });

    socket.on('game_move', (data) => {
      // data: { roomId, details: { colIdx, exitingStone: { id, value, color } } }
      // Gelen hamleyi odadaki diğer oyuncuya ilet
      console.log(`[Socket] Hamle: ${socket.id} -> oda ${data.roomId}, sütun ${data.details.colIdx}`);
      socket.to(data.roomId).emit('opponent_move', data.details);
    });

    socket.on('game_end', (data) => {
      socket.to(data.roomId).emit('game_end', data.details);
      // Odayı temizle
      delete rooms[data.roomId];
    });

    socket.on('disconnect', () => {
      console.log('[Socket] Bağlantı koptu:', socket.id);
      
      // Bekleyenlerden sil
      const index = waitingPlayers.findIndex(p => p.socketId === socket.id);
      if (index !== -1) waitingPlayers.splice(index, 1);

      // Odalardan birindeyse diğerine haber ver
      for (const roomId in rooms) {
        const room = rooms[roomId];
        if (room.players.some(p => p.id === socket.id)) {
          socket.to(roomId).emit('opponent_disconnected');
          delete rooms[roomId];
          break;
        }
      }
    });
  });
};
