const Medication = require('../models/Medication');

const DEMO_UID = process.env.DEMO_UID || 'demo-shared';

// Get user's medications
exports.getMyMedications = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const medications = await Medication.find({ userUid: DEMO_UID })
      .sort({ startDate: -1 })
      .lean();

    res.json(medications);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch medications', details: e.message });
  }
};

// Get today's medication reminders
exports.getTodayReminders = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const medications = await Medication.find({
      userUid: DEMO_UID,
      startDate: { $lte: tomorrow },
      $or: [
        { endDate: { $exists: false } },
        { endDate: null },
        { endDate: { $gte: today } },
      ],
    }).lean();

    // Filter by times for today
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTimeMinutes = currentHour * 60 + currentMinute;

    let todayReminders = medications
      .map((med) => {
        const reminders = (med.times || []).map((timeStr) => {
          const [hours, minutes] = timeStr.split(':').map(Number);
          const timeMinutes = hours * 60 + minutes;
          
          // Only include reminders for today that haven't passed (or are within the next hour)
          const timeUntil = timeMinutes - currentTimeMinutes;
          if (timeUntil >= -60) { // Include reminders up to 1 hour ago
            return {
              medicationId: med._id,
              name: med.name,
              dosage: med.dosage,
              time: timeStr,
              timeUntil,
            };
          }
          return null;
        }).filter(Boolean);

        return reminders;
      })
      .flat()
      .sort((a, b) => a.timeUntil - b.timeUntil) // Sort by time (earliest first)
      .slice(0, 5); // Limit to 5 reminders

    // If no medications found, return dummy data
    if (todayReminders.length === 0) {
      const dummyReminders = [
        {
          medicationId: 'dummy-1',
          name: 'Vitamin D',
          dosage: '1000 IU',
          time: '08:00',
          timeUntil: 60,
        },
        {
          medicationId: 'dummy-2',
          name: 'Aspirin',
          dosage: '81 mg',
          time: '12:00',
          timeUntil: 240,
        },
        {
          medicationId: 'dummy-3',
          name: 'Multivitamin',
          dosage: '1 tablet',
          time: '19:00',
          timeUntil: 600,
        },
      ];
      todayReminders = dummyReminders;
    }

    res.json(todayReminders);
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch today reminders', details: e.message });
  }
};

// Add medication (for future use)
exports.addMedication = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const { name, dosage, frequency, times, startDate, endDate, notes } = req.body;

    if (!name || !dosage || !times || !startDate) {
      return res.status(400).json({ error: 'Missing required fields: name, dosage, times, startDate' });
    }

    const medication = new Medication({
      userUid: DEMO_UID,
      name,
      dosage,
      frequency: frequency || 'daily',
      times: Array.isArray(times) ? times : [times],
      startDate: new Date(startDate),
      endDate: endDate ? new Date(endDate) : null,
      notes,
    });

    await medication.save();
    res.status(201).json(medication);
  } catch (e) {
    res.status(500).json({ error: 'Failed to add medication', details: e.message });
  }
};

// Delete medication
exports.deleteMedication = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });

    const { id } = req.params;
    
    const medication = await Medication.findOne({ _id: id, userUid: DEMO_UID });
    
    if (!medication) {
      return res.status(404).json({ error: 'Medication not found' });
    }

    await Medication.deleteOne({ _id: id });
    res.status(200).json({ message: 'Medication deleted successfully' });
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete medication', details: e.message });
  }
};

