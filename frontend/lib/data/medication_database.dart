/// Comprehensive medication database with common medications
/// This dataset includes real medication names for autocomplete functionality
class MedicationDatabase {
  static final List<MedicationInfo> medications = [
    // Pain Relief & Anti-inflammatory
    MedicationInfo(name: 'Acetaminophen', category: 'Pain Relief', commonDosages: ['500mg', '650mg', '1000mg']),
    MedicationInfo(name: 'Ibuprofen', category: 'Pain Relief', commonDosages: ['200mg', '400mg', '600mg', '800mg']),
    MedicationInfo(name: 'Aspirin', category: 'Pain Relief', commonDosages: ['81mg', '325mg', '500mg']),
    MedicationInfo(name: 'Naproxen', category: 'Pain Relief', commonDosages: ['220mg', '250mg', '375mg', '500mg']),
    MedicationInfo(name: 'Diclofenac', category: 'Pain Relief', commonDosages: ['25mg', '50mg', '75mg', '100mg']),
    MedicationInfo(name: 'Celecoxib', category: 'Pain Relief', commonDosages: ['100mg', '200mg', '400mg']),
    MedicationInfo(name: 'Meloxicam', category: 'Pain Relief', commonDosages: ['7.5mg', '15mg']),
    MedicationInfo(name: 'Tramadol', category: 'Pain Relief', commonDosages: ['50mg', '100mg', '200mg', '300mg']),
    
    // Antibiotics
    MedicationInfo(name: 'Amoxicillin', category: 'Antibiotic', commonDosages: ['250mg', '500mg', '875mg']),
    MedicationInfo(name: 'Azithromycin', category: 'Antibiotic', commonDosages: ['250mg', '500mg']),
    MedicationInfo(name: 'Ciprofloxacin', category: 'Antibiotic', commonDosages: ['250mg', '500mg', '750mg']),
    MedicationInfo(name: 'Doxycycline', category: 'Antibiotic', commonDosages: ['50mg', '100mg']),
    MedicationInfo(name: 'Cephalexin', category: 'Antibiotic', commonDosages: ['250mg', '500mg']),
    MedicationInfo(name: 'Levofloxacin', category: 'Antibiotic', commonDosages: ['250mg', '500mg', '750mg']),
    MedicationInfo(name: 'Clindamycin', category: 'Antibiotic', commonDosages: ['150mg', '300mg']),
    MedicationInfo(name: 'Metronidazole', category: 'Antibiotic', commonDosages: ['250mg', '500mg']),
    
    // Antihypertensives (Blood Pressure)
    MedicationInfo(name: 'Lisinopril', category: 'Blood Pressure', commonDosages: ['2.5mg', '5mg', '10mg', '20mg', '40mg']),
    MedicationInfo(name: 'Amlodipine', category: 'Blood Pressure', commonDosages: ['2.5mg', '5mg', '10mg']),
    MedicationInfo(name: 'Losartan', category: 'Blood Pressure', commonDosages: ['25mg', '50mg', '100mg']),
    MedicationInfo(name: 'Metoprolol', category: 'Blood Pressure', commonDosages: ['25mg', '50mg', '100mg', '200mg']),
    MedicationInfo(name: 'Atenolol', category: 'Blood Pressure', commonDosages: ['25mg', '50mg', '100mg']),
    MedicationInfo(name: 'Hydrochlorothiazide', category: 'Blood Pressure', commonDosages: ['12.5mg', '25mg', '50mg']),
    MedicationInfo(name: 'Valsartan', category: 'Blood Pressure', commonDosages: ['40mg', '80mg', '160mg', '320mg']),
    MedicationInfo(name: 'Enalapril', category: 'Blood Pressure', commonDosages: ['2.5mg', '5mg', '10mg', '20mg']),
    
    // Diabetes Medications
    MedicationInfo(name: 'Metformin', category: 'Diabetes', commonDosages: ['500mg', '850mg', '1000mg']),
    MedicationInfo(name: 'Glipizide', category: 'Diabetes', commonDosages: ['5mg', '10mg']),
    MedicationInfo(name: 'Glyburide', category: 'Diabetes', commonDosages: ['1.25mg', '2.5mg', '5mg']),
    MedicationInfo(name: 'Sitagliptin', category: 'Diabetes', commonDosages: ['25mg', '50mg', '100mg']),
    MedicationInfo(name: 'Insulin Glargine', category: 'Diabetes', commonDosages: ['100 units/mL']),
    MedicationInfo(name: 'Insulin Lispro', category: 'Diabetes', commonDosages: ['100 units/mL']),
    MedicationInfo(name: 'Empagliflozin', category: 'Diabetes', commonDosages: ['10mg', '25mg']),
    
    // Cholesterol/Statins
    MedicationInfo(name: 'Atorvastatin', category: 'Cholesterol', commonDosages: ['10mg', '20mg', '40mg', '80mg']),
    MedicationInfo(name: 'Simvastatin', category: 'Cholesterol', commonDosages: ['5mg', '10mg', '20mg', '40mg', '80mg']),
    MedicationInfo(name: 'Rosuvastatin', category: 'Cholesterol', commonDosages: ['5mg', '10mg', '20mg', '40mg']),
    MedicationInfo(name: 'Pravastatin', category: 'Cholesterol', commonDosages: ['10mg', '20mg', '40mg', '80mg']),
    
    // Gastrointestinal
    MedicationInfo(name: 'Omeprazole', category: 'Gastrointestinal', commonDosages: ['10mg', '20mg', '40mg']),
    MedicationInfo(name: 'Pantoprazole', category: 'Gastrointestinal', commonDosages: ['20mg', '40mg']),
    MedicationInfo(name: 'Esomeprazole', category: 'Gastrointestinal', commonDosages: ['20mg', '40mg']),
    MedicationInfo(name: 'Ranitidine', category: 'Gastrointestinal', commonDosages: ['75mg', '150mg', '300mg']),
    MedicationInfo(name: 'Ondansetron', category: 'Gastrointestinal', commonDosages: ['4mg', '8mg']),
    MedicationInfo(name: 'Metoclopramide', category: 'Gastrointestinal', commonDosages: ['5mg', '10mg']),
    
    // Antihistamines/Allergy
    MedicationInfo(name: 'Cetirizine', category: 'Allergy', commonDosages: ['5mg', '10mg']),
    MedicationInfo(name: 'Loratadine', category: 'Allergy', commonDosages: ['5mg', '10mg']),
    MedicationInfo(name: 'Fexofenadine', category: 'Allergy', commonDosages: ['30mg', '60mg', '120mg', '180mg']),
    MedicationInfo(name: 'Diphenhydramine', category: 'Allergy', commonDosages: ['25mg', '50mg']),
    MedicationInfo(name: 'Montelukast', category: 'Allergy', commonDosages: ['4mg', '5mg', '10mg']),
    
    // Respiratory/Asthma
    MedicationInfo(name: 'Albuterol', category: 'Respiratory', commonDosages: ['90mcg/inhaler', '2mg', '4mg']),
    MedicationInfo(name: 'Fluticasone', category: 'Respiratory', commonDosages: ['44mcg', '110mcg', '220mcg']),
    MedicationInfo(name: 'Budesonide', category: 'Respiratory', commonDosages: ['90mcg', '180mcg']),
    MedicationInfo(name: 'Ipratropium', category: 'Respiratory', commonDosages: ['17mcg/inhaler']),
    
    // Antidepressants/Mental Health
    MedicationInfo(name: 'Sertraline', category: 'Mental Health', commonDosages: ['25mg', '50mg', '100mg']),
    MedicationInfo(name: 'Fluoxetine', category: 'Mental Health', commonDosages: ['10mg', '20mg', '40mg']),
    MedicationInfo(name: 'Escitalopram', category: 'Mental Health', commonDosages: ['5mg', '10mg', '20mg']),
    MedicationInfo(name: 'Citalopram', category: 'Mental Health', commonDosages: ['10mg', '20mg', '40mg']),
    MedicationInfo(name: 'Venlafaxine', category: 'Mental Health', commonDosages: ['37.5mg', '75mg', '150mg']),
    MedicationInfo(name: 'Duloxetine', category: 'Mental Health', commonDosages: ['20mg', '30mg', '60mg']),
    MedicationInfo(name: 'Bupropion', category: 'Mental Health', commonDosages: ['75mg', '100mg', '150mg', '300mg']),
    MedicationInfo(name: 'Mirtazapine', category: 'Mental Health', commonDosages: ['7.5mg', '15mg', '30mg', '45mg']),
    
    // Anxiolytics/Benzodiazepines
    MedicationInfo(name: 'Alprazolam', category: 'Anxiety', commonDosages: ['0.25mg', '0.5mg', '1mg', '2mg']),
    MedicationInfo(name: 'Lorazepam', category: 'Anxiety', commonDosages: ['0.5mg', '1mg', '2mg']),
    MedicationInfo(name: 'Clonazepam', category: 'Anxiety', commonDosages: ['0.5mg', '1mg', '2mg']),
    MedicationInfo(name: 'Diazepam', category: 'Anxiety', commonDosages: ['2mg', '5mg', '10mg']),
    
    // Thyroid
    MedicationInfo(name: 'Levothyroxine', category: 'Thyroid', commonDosages: ['25mcg', '50mcg', '75mcg', '88mcg', '100mcg', '112mcg', '125mcg', '137mcg', '150mcg']),
    MedicationInfo(name: 'Liothyronine', category: 'Thyroid', commonDosages: ['5mcg', '25mcg', '50mcg']),
    
    // Anticoagulants
    MedicationInfo(name: 'Warfarin', category: 'Anticoagulant', commonDosages: ['1mg', '2mg', '2.5mg', '3mg', '4mg', '5mg', '6mg', '7.5mg', '10mg']),
    MedicationInfo(name: 'Apixaban', category: 'Anticoagulant', commonDosages: ['2.5mg', '5mg']),
    MedicationInfo(name: 'Rivaroxaban', category: 'Anticoagulant', commonDosages: ['10mg', '15mg', '20mg']),
    MedicationInfo(name: 'Clopidogrel', category: 'Anticoagulant', commonDosages: ['75mg']),
    
    // Vitamins & Supplements
    MedicationInfo(name: 'Vitamin D3', category: 'Vitamin', commonDosages: ['1000 IU', '2000 IU', '5000 IU', '10000 IU']),
    MedicationInfo(name: 'Vitamin B12', category: 'Vitamin', commonDosages: ['500mcg', '1000mcg', '2500mcg']),
    MedicationInfo(name: 'Folic Acid', category: 'Vitamin', commonDosages: ['400mcg', '800mcg', '1mg']),
    MedicationInfo(name: 'Iron Supplement', category: 'Vitamin', commonDosages: ['65mg', '325mg']),
    MedicationInfo(name: 'Calcium Carbonate', category: 'Vitamin', commonDosages: ['500mg', '600mg', '1000mg']),
    MedicationInfo(name: 'Multivitamin', category: 'Vitamin', commonDosages: ['1 tablet']),
    MedicationInfo(name: 'Omega-3 Fish Oil', category: 'Vitamin', commonDosages: ['1000mg', '1200mg']),
    
    // Sleep Aids
    MedicationInfo(name: 'Zolpidem', category: 'Sleep Aid', commonDosages: ['5mg', '10mg']),
    MedicationInfo(name: 'Melatonin', category: 'Sleep Aid', commonDosages: ['1mg', '3mg', '5mg', '10mg']),
    MedicationInfo(name: 'Trazodone', category: 'Sleep Aid', commonDosages: ['25mg', '50mg', '100mg']),
    
    // Migraine/Headache
    MedicationInfo(name: 'Sumatriptan', category: 'Migraine', commonDosages: ['25mg', '50mg', '100mg']),
    MedicationInfo(name: 'Rizatriptan', category: 'Migraine', commonDosages: ['5mg', '10mg']),
    MedicationInfo(name: 'Topiramate', category: 'Migraine', commonDosages: ['25mg', '50mg', '100mg', '200mg']),
    
    // Antiseizure/Epilepsy
    MedicationInfo(name: 'Gabapentin', category: 'Antiseizure', commonDosages: ['100mg', '300mg', '400mg', '600mg', '800mg']),
    MedicationInfo(name: 'Pregabalin', category: 'Antiseizure', commonDosages: ['25mg', '50mg', '75mg', '100mg', '150mg', '200mg', '300mg']),
    MedicationInfo(name: 'Levetiracetam', category: 'Antiseizure', commonDosages: ['250mg', '500mg', '750mg', '1000mg']),
    MedicationInfo(name: 'Lamotrigine', category: 'Antiseizure', commonDosages: ['25mg', '50mg', '100mg', '150mg', '200mg']),
    
    // Osteoporosis
    MedicationInfo(name: 'Alendronate', category: 'Osteoporosis', commonDosages: ['5mg', '10mg', '35mg', '70mg']),
    MedicationInfo(name: 'Risedronate', category: 'Osteoporosis', commonDosages: ['5mg', '35mg', '150mg']),
    
    // Prostate
    MedicationInfo(name: 'Tamsulosin', category: 'Prostate', commonDosages: ['0.4mg']),
    MedicationInfo(name: 'Finasteride', category: 'Prostate', commonDosages: ['1mg', '5mg']),
    
    // Gout
    MedicationInfo(name: 'Allopurinol', category: 'Gout', commonDosages: ['100mg', '300mg']),
    MedicationInfo(name: 'Colchicine', category: 'Gout', commonDosages: ['0.6mg']),
    
    // Birth Control
    MedicationInfo(name: 'Ethinyl Estradiol/Levonorgestrel', category: 'Birth Control', commonDosages: ['0.03mg/0.15mg']),
    MedicationInfo(name: 'Drospirenone/Ethinyl Estradiol', category: 'Birth Control', commonDosages: ['3mg/0.03mg']),
    
    // Corticosteroids
    MedicationInfo(name: 'Prednisone', category: 'Corticosteroid', commonDosages: ['2.5mg', '5mg', '10mg', '20mg', '50mg']),
    MedicationInfo(name: 'Methylprednisolone', category: 'Corticosteroid', commonDosages: ['4mg', '8mg', '16mg', '32mg']),
    MedicationInfo(name: 'Dexamethasone', category: 'Corticosteroid', commonDosages: ['0.5mg', '0.75mg', '1mg', '1.5mg', '2mg', '4mg', '6mg']),
    
    // Muscle Relaxants
    MedicationInfo(name: 'Cyclobenzaprine', category: 'Muscle Relaxant', commonDosages: ['5mg', '10mg']),
    MedicationInfo(name: 'Baclofen', category: 'Muscle Relaxant', commonDosages: ['10mg', '20mg']),
    MedicationInfo(name: 'Tizanidine', category: 'Muscle Relaxant', commonDosages: ['2mg', '4mg']),
    
    // Antifungal
    MedicationInfo(name: 'Fluconazole', category: 'Antifungal', commonDosages: ['50mg', '100mg', '150mg', '200mg']),
    MedicationInfo(name: 'Terbinafine', category: 'Antifungal', commonDosages: ['250mg']),
    
    // Antiviral
    MedicationInfo(name: 'Acyclovir', category: 'Antiviral', commonDosages: ['200mg', '400mg', '800mg']),
    MedicationInfo(name: 'Valacyclovir', category: 'Antiviral', commonDosages: ['500mg', '1000mg']),
    
    // Diuretics
    MedicationInfo(name: 'Furosemide', category: 'Diuretic', commonDosages: ['20mg', '40mg', '80mg']),
    MedicationInfo(name: 'Spironolactone', category: 'Diuretic', commonDosages: ['25mg', '50mg', '100mg']),
    
    // Parkinson's Disease
    MedicationInfo(name: 'Carbidopa/Levodopa', category: 'Parkinson\'s', commonDosages: ['10mg/100mg', '25mg/100mg', '25mg/250mg']),
    
    // ADD/ADHD
    MedicationInfo(name: 'Methylphenidate', category: 'ADHD', commonDosages: ['5mg', '10mg', '18mg', '20mg', '27mg', '36mg', '54mg']),
    MedicationInfo(name: 'Amphetamine/Dextroamphetamine', category: 'ADHD', commonDosages: ['5mg', '10mg', '15mg', '20mg', '25mg', '30mg']),
    MedicationInfo(name: 'Atomoxetine', category: 'ADHD', commonDosages: ['10mg', '18mg', '25mg', '40mg', '60mg', '80mg', '100mg']),
  ];

  /// Search medications by name (case-insensitive, fuzzy matching)
  static List<MedicationInfo> search(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    final results = <MedicationInfo>[];
    
    // Exact matches first
    for (final med in medications) {
      if (med.name.toLowerCase() == lowerQuery) {
        results.add(med);
      }
    }
    
    // Starts with query
    for (final med in medications) {
      if (med.name.toLowerCase().startsWith(lowerQuery) && !results.contains(med)) {
        results.add(med);
      }
    }
    
    // Contains query
    for (final med in medications) {
      if (med.name.toLowerCase().contains(lowerQuery) && !results.contains(med)) {
        results.add(med);
      }
    }
    
    // Limit to 20 results
    return results.take(20).toList();
  }
  
  /// Get all medication names
  static List<String> getAllNames() {
    return medications.map((m) => m.name).toList();
  }
  
  /// Get medications by category
  static List<MedicationInfo> getByCategory(String category) {
    return medications.where((m) => m.category == category).toList();
  }
  
  /// Get all unique categories
  static List<String> getAllCategories() {
    final categories = medications.map((m) => m.category).toSet().toList();
    categories.sort();
    return categories;
  }
}

/// Model for medication information
class MedicationInfo {
  final String name;
  final String category;
  final List<String> commonDosages;
  
  MedicationInfo({
    required this.name,
    required this.category,
    required this.commonDosages,
  });
}

