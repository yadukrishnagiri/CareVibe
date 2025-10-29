exports.getDoctors = (_req, res) => {
  res.json([
    { name: 'Dr. Priya Menon', specialty: 'Cardiologist', distance: '2.1 km' },
    { name: 'Dr. Vivek Rao', specialty: 'Dermatologist', distance: '3.4 km' },
    { name: 'Dr. Asha Thomas', specialty: 'Neurologist', distance: '4.0 km' },
  ]);
};


