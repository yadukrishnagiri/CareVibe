const mongoose = require('mongoose');

const HealthMetricSchema = new mongoose.Schema(
  {
    userUid: { type: String, index: true, required: true },
    date: { type: Date, required: true },
    weightKg: Number,
    remSleepHr: Number,
    stressLevel: Number,
    bmi: Number,
    sleepInterruptions: Number,
    bloodPressureMmHg: String,
    stepCount: Number,
    restingHeartRateBpm: Number,
    spo2Percent: Number,
    exerciseDurationMin: Number,
    bodyTemperatureC: Number,
    physicalActivityLevel: String,
    caloriesBurned: Number,
    sleepDurationHr: Number,
    smokingStatus: String,
    alcoholConsumption: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model('HealthMetric', HealthMetricSchema);



