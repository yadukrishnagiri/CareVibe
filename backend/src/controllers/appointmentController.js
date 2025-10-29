const Appointment = require('../models/Appointment');

exports.getAppointments = async (req, res) => {
  const { userId } = req.params;
  if (!userId) return res.status(400).json({ error: 'userId is required' });
  const items = await Appointment.find({ userUid: userId }).sort({ date: 1 }).limit(10);
  res.json(items);
};


