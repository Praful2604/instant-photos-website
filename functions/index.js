const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
const {Storage} = require("@google-cloud/storage");

admin.initializeApp();
const storage = new Storage();

// Cloud Function to copy or delete favorite photos in album_photos bucket
exports.manageFavoritePhoto = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { action, sourcePath, destinationPath } = req.body;

      if (!action || !sourcePath || !destinationPath) {
        return res.status(400).send("Missing required parameters");
      }

      const sourceBucket = admin.storage().bucket();
      const destBucket = admin.storage().bucket();

      if (action === "copy") {
        // Copy object from source to album_photos bucket path
        await sourceBucket.file(sourcePath).copy(destBucket.file(destinationPath));
        return res.status(200).send("Copy operation successful");
      } else if (action === "delete") {
        // Delete object from album_photos bucket path
        await destBucket.file(destinationPath).delete();
        return res.status(200).send("Delete operation successful");
      } else {
        return res.status(400).send("Invalid action");
      }
    } catch (error) {
      console.error("Error managing favorite photo:", error);
      return res.status(500).send(error.toString());
    }
  });
});
