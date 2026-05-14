require('dotenv').config();
const prisma = require('./utils/prisma');

async function deduplicateUsernames() {
  const users = await prisma.user.findMany();
  const usernameCounts = {};

  for (const user of users) {
    if (usernameCounts[user.username]) {
      usernameCounts[user.username]++;
      const newUsername = `${user.username}_${usernameCounts[user.username]}`;
      await prisma.user.update({
        where: { id: user.id },
        data: { username: newUsername }
      });
      console.log(`Updated ${user.username} -> ${newUsername}`);
    } else {
      usernameCounts[user.username] = 1;
    }
  }
  console.log("Deduplication complete.");
}

deduplicateUsernames().catch(console.error).finally(() => prisma.$disconnect());
