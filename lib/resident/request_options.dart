/// Documents a resident can request, and the fee shown in the notice.
/// Change the amounts to match your barangay's ordinance.
const Map<String, String> requestFees = {
  'Barangay Clearance': '₱100.00',
  'Certificate of Residency': '₱100.00',
  'Certificate of Indigency': 'Free',
  'Barangay Business Permit / Clearance': '₱500.00',
  'Certificate to File Action': '₱150.00',
};

/// General requirements for every request.
/// Key = column in the "concerns" table (stores the uploaded file ID).
const Map<String, String> requirementLabels = {
  'validIdFront': 'Valid ID (Front)',
  'validIdBack': 'Valid ID (Back)',
  'proofOfAddress': 'Proof of Address',
  'cedula': 'Cedula (Community Tax Certificate)',
};
