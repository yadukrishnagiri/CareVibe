const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    uid: { type: String, unique: true, index: true },
    email: String,
    displayName: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', UserSchema);


