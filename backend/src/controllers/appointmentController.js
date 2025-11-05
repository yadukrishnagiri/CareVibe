const Appointment = require('../models/Appointment');

const DEMO_UID = process.env.DEMO_UID || 'demo-shared';

exports.getAppointments = async (req, res) => {
  const { userId } = req.params;
  if (!userId) return res.status(400).json({ error: 'userId is required' });
  
  let items = await Appointment.find({ userUid: DEMO_UID }).sort({ date: 1 }).limit(10);
  
  // Always return dummy data for demo (even if DB has entries, we override for consistency)
  // Use realistic appointment times (avoid early morning hours)
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(14, 0, 0, 0); // 2 PM
  tomorrow.setMinutes(0);
  tomorrow.setSeconds(0);
  tomorrow.setMilliseconds(0);
  
  const nextWeek = new Date();
  nextWeek.setDate(nextWeek.getDate() + 7);
  nextWeek.setHours(10, 30, 0, 0); // 10:30 AM
  nextWeek.setMinutes(0);
  nextWeek.setSeconds(0);
  nextWeek.setMilliseconds(0);
  
  items = [
    {
      doctorName: 'Dr. Sarah Johnson',
      date: tomorrow.toISOString(),
      notes: 'Annual checkup',
    },
    {
      doctorName: 'Dr. Michael Chen',
      date: nextWeek.toISOString(),
      notes: 'Cardiology consultation',
    },
  ];
  
  res.json(items);
};


