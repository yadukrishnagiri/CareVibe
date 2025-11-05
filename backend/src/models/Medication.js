const mongoose = require('mongoose');

const MedicationSchema = new mongoose.Schema(
  {
    userUid: { type: String, index: true, required: true },
    name: { type: String, required: true },
    dosage: { type: String, required: true },
    frequency: { type: String, default: 'daily' }, // 'daily', 'twice-daily', etc.
    times: [{ type: String }], // ['08:00', '20:00']
    startDate: { type: Date, required: true },
    endDate: { type: Date }, // Optional
    notes: { type: String },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Medication', MedicationSchema);

