const admin = require('../config/firebase-admin');

const verifyToken = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: 'Token gerekli' });

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded; // Token doğruysa user bilgisini req objesine ekle
    next();
  } catch (error) {
    res.status(401).json({ error: 'Geçersiz token' });
  }
};

module.exports = { verifyToken };
