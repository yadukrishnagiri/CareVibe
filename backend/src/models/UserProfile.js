const mongoose = require('mongoose');

const UserProfileSchema = new mongoose.Schema(
  {
    uid: { type: String, index: true, unique: true, required: true },
    age: { type: Number, min: 0, max: 120 },
    gender: { type: String, enum: ['male', 'female', 'other'] },
    heightCm: { type: Number, min: 30, max: 260 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserProfile', UserProfileSchema);


