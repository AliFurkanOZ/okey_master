const { Server } = require('socket.io');

const waitingPlayers = []; // { socketId, nickname, type }
const rooms = {}; // { roomId: { players: [], gameState: {} } }

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
        
        rooms[roomId] = {
          roomId,
          players: [
            { id: socket.id, nickname: nickname },
            { id: opponent.socketId, nickname: opponent.nickname }
          ]
        };

        // Rastgele kimin başlayacağını seç
        const firstPlayerIdx = Math.random() < 0.5 ? 0 : 1;
        
        io.to(roomId).emit('game_start', {
          roomId,
          players: rooms[roomId].players,
          firstTurn: rooms[roomId].players[firstPlayerIdx].id
        });
        
        console.log(`[Socket] Maç başladı: ${roomId} (${nickname} vs ${opponent.nickname})`);
      } else {
        waitingPlayers.push({ socketId: socket.id, nickname, type });
      }
    });

    socket.on('game_move', (data) => {
      // data: { roomId, action: 'move', details: {...} }
      // Gelen hamleyi odadaki diğer oyuncuya ilet
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
