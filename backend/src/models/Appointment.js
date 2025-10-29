const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema(
  {
    userUid: { type: String, index: true },
    doctorName: String,
    date: Date,
    notes: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model('Appointment', AppointmentSchema);


