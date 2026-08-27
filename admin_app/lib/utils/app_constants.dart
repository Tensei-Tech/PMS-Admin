// lib/utils/app_constants.dart

/// Central constants for unit types, designations, districts, and police stations in Admin Console.
class AppConstants {
  AppConstants._();

  static const List<String> unitTypes = [
    'Commissionerate Police',
    'Rural Police',
  ];

  static const List<String> commissionerateDesignations = [
    'PC',
    'NPC',
    'HC',
    'ASI',
    'PSI',
    'API',
    'PI',
    'Sr. PI',
    'ACP',
    'DCP',
    'Addl. CP',
    'JT. CP',
    'CP',
  ];

  static const List<String> ruralDesignations = [
    'PC',
    'NPC',
    'HC',
    'ASI',
    'PSI',
    'API',
    'PI',
    'Sr. PI',
    'Dy. SP',
    'ASP',
    'Addl. SP',
    'SP',
  ];

  static const List<String> allDesignations = [
    'PC',
    'NPC',
    'HC',
    'ASI',
    'PSI',
    'API',
    'PI',
    'Sr. PI',
    'ACP',
    'DCP',
    'Addl. CP',
    'JT. CP',
    'CP',
    'Dy. SP',
    'ASP',
    'Addl. SP',
    'SP',
  ];

  /// Returns designation options for a given unit type.
  static List<String> getDesignationsForUnitType(String? unitType) {
    if (unitType == 'Commissionerate Police' || unitType == 'Commissionerate') {
      return commissionerateDesignations;
    } else if (unitType == 'Rural Police' || unitType == 'Superintendent of Police') {
      return ruralDesignations;
    }
    return allDesignations;
  }

  /// Returns implied unit type if designation is rank-locked to CP or SP levels.
  static String? getImpliedUnitType(String? designation) {
    if (designation == null) return null;
    const cpRanks = ['ACP', 'DCP', 'Addl. CP', 'JT. CP', 'CP'];
    const spRanks = ['Dy. SP', 'ASP', 'Addl. SP', 'SP'];
    if (cpRanks.contains(designation)) return 'Commissionerate Police';
    if (spRanks.contains(designation)) return 'Rural Police';
    return null;
  }

  static const Map<String, List<String>> districtsByUnitType = {
    'Commissionerate Police': [
      'Mumbai City',
      'Thane City',
      'Pune City',
      'Nagpur City',
      'Pimpri Chinchwad',
      'Navi Mumbai',
      'Mira Bhayandar Vasai Virar',
      'Nashik City',
      'Chhatrapati Sambhajinagar City',
      'Solapur City',
      'Amravati City',
    ],
    'Rural Police': [
      'Thane Rural',
      'Pune Rural',
      'Nagpur Rural',
      'Nashik Rural',
      'Raigad',
      'Palghar',
      'Satara',
      'Sangli',
      'Solapur Rural',
      'Kolhapur',
      'Ahmednagar',
      'Aurangabad Rural',
      'Amravati Rural',
      'Nanded',
      'Jalgaon',
      'Latur',
      'Ratnagiri',
      'Sindhudurg',
    ],
  };

  /// Returns list of districts/cities for the given unit type.
  static List<String> getDistrictsForUnitType(String? unitType) {
    if (unitType == 'Commissionerate Police' || unitType == 'Commissionerate') {
      return districtsByUnitType['Commissionerate Police']!;
    } else if (unitType == 'Rural Police' || unitType == 'Superintendent of Police') {
      return districtsByUnitType['Rural Police']!;
    }
    return [
      ...districtsByUnitType['Commissionerate Police']!,
      ...districtsByUnitType['Rural Police']!,
    ];
  }

  static const Map<String, List<String>> stationsByDistrict = {
    'Mumbai City': ['Colaba PS', 'Marine Drive PS', 'Azad Maidan PS', 'Malabar Hill PS', 'Worli PS', 'Bandra PS', 'Andheri PS', 'Kurla PS'],
    'Thane City': ['Thane Nagar PS', 'Naupada PS', 'Kopri PS', 'Wagle Estate PS', 'Vartak Nagar PS', 'Kalyan PS', 'Dombivli PS'],
    'Pune City': ['Shivajinagar PS', 'Deccan Gymkhana PS', 'Kothrud PS', 'Hadapsar PS', 'Koregaon Park PS', 'Cantonment PS', 'Viman Nagar PS'],
    'Nagpur City': ['Sitabuldi PS', 'Sadar PS', 'Dhantoli PS', 'Ambazari PS', 'Gittikhadan PS', 'Lakadganj PS'],
    'Pimpri Chinchwad': ['Pimpri PS', 'Chinchwad PS', 'Nigdi PS', 'Bhosari PS', 'Wakad PS', 'Hinjawadi PS'],
    'Navi Mumbai': ['Vashi PS', 'Nerul PS', 'Belapur PS', 'Kharghar PS', 'Panvel PS', 'Rabale PS'],
    'Mira Bhayandar Vasai Virar': ['Mira Road PS', 'Bhayandar PS', 'Vasai PS', 'Nallasopara PS', 'Virar PS', 'Manickpur PS'],
    'Nashik City': ['Bhadrakali PS', 'Panchavati PS', 'Sarkarwada PS', 'Gangapur PS', 'Ambad PS', 'Indiranagar PS'],
    'Chhatrapati Sambhajinagar City': ['City Chowk PS', 'Kranti Chowk PS', 'Jawaharnagar PS', 'Cidco PS', 'Mukundwadi PS'],
    'Solapur City': ['Faujdar Chawda PS', 'Jodi Basaveshwar PS', 'Sadar Bazar PS', 'Vijapur Naka PS', 'MIDC PS'],
    'Amravati City': ['Kotwali PS', 'Rajapeth PS', 'Frezerpura PS', 'Badnera PS', 'Gadge Nagar PS'],
    'Thane Rural': ['Bhayander Rural PS', 'Ganeshpuri PS', 'Kashimira PS', 'Murbad PS', 'Shahapur PS', 'Tokawade PS'],
    'Pune Rural': ['Baramati City PS', 'Bhor PS', 'Daund PS', 'Haveli PS', 'Lonavala City PS', 'Manchar PS', 'Shirur PS'],
    'Nagpur Rural': ['Kamptee PS', 'Hingna PS', 'Kalmeshwar PS', 'Umred PS', 'Ramtek PS', 'Katol PS'],
    'Nashik Rural': ['Chandwad PS', 'Igatpuri PS', 'Malegaon City PS', 'Niphad PS', 'Sinnar PS', 'Yeola PS'],
    'Raigad': ['Alibag PS', 'Karjat PS', 'Mahad PS', 'Mangaon PS', 'Murud PS', 'Pen PS', 'Roha PS'],
    'Palghar': ['Boisar PS', 'Dahanu PS', 'Kasa PS', 'Palghar PS', 'Talasari PS', 'Vikramgad PS'],
    'Satara': ['Satara City PS', 'Karad City PS', 'Phaltan City PS', 'Wai PS', 'Mahabaleshwar PS', 'Koregaon PS'],
    'Sangli': ['Sangli City PS', 'Miraj City PS', 'Vita PS', 'Islampur PS', 'Tasgaon PS', 'Palus PS'],
    'Solapur Rural': ['Barshi City PS', 'Karmala PS', 'Kurduwadi PS', 'Pandharpur City PS', 'Sangola PS', 'Akkalkot PS'],
    'Kolhapur': ['Juna Rajwada PS', 'Laxmipuri PS', 'Shahupuri PS', 'Ichalkaranji PS', 'Gargoti PS', 'Kagal PS', 'Gadhinklaj PS'],
    'Ahmednagar': ['Kotwali PS', 'Topkhana PS', 'Camp PS', 'Shirdi PS', 'Sangamner City PS', 'Shrirampur City PS'],
    'Aurangabad Rural': ['Gangapur PS', 'Kannad PS', 'Paithan PS', 'Sillod PS', 'Vaijapur PS'],
    'Amravati Rural': ['Achalpur PS', 'Anjangaon Surji PS', 'Chandur Bazar PS', 'Dhamangaon Railway PS', 'Morshi PS', 'Paratwada PS'],
    'Nanded': ['Itwara PS', 'Vazirabad PS', 'Shivajinagar PS', 'Degloor PS', 'Kandhar PS', 'Kinwat PS', 'Mukhed PS'],
    'Jalgaon': ['Jalgaon City PS', 'Ramanand Nagar PS', 'Zilla Peth PS', 'Bhusawal City PS', 'Chalisgaon City PS', 'Amalner PS'],
    'Latur': ['Gandhi Chowk PS', 'Shivajinagar PS', 'MIDC Latur PS', 'Ausa PS', 'Ahmedpur PS', 'Udgir City PS'],
    'Ratnagiri': ['Ratnagiri City PS', 'Chiplun PS', 'Dabhol PS', 'Guhagar PS', 'Khed PS', 'Rajapur PS'],
    'Sindhudurg': ['Kudal PS', 'Kankavli PS', 'Sawantwadi PS', 'Malvan PS', 'Vengurla PS', 'Devgad PS'],
  };

  static const List<String> allIndiaStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  static const Map<String, List<String>> stateDistrictsMap = {
    'Maharashtra': [
      'Ahmednagar',
      'Akola',
      'Amravati',
      'Amravati City',
      'Amravati Rural',
      'Beed',
      'Bhandara',
      'Buldhana',
      'Chandrapur',
      'Chhatrapati Sambhajinagar',
      'Chhatrapati Sambhajinagar City',
      'Dhule',
      'Gadchiroli',
      'Gondia',
      'Hingoli',
      'Jalgaon',
      'Jalna',
      'Kolhapur',
      'Latur',
      'Mira Bhayandar Vasai Virar',
      'Mumbai City',
      'Mumbai Suburban',
      'Nagpur',
      'Nagpur City',
      'Nagpur Rural',
      'Nanded',
      'Nandurbar',
      'Nashik',
      'Nashik City',
      'Nashik Rural',
      'Navi Mumbai',
      'Osmanabad (Dharashiv)',
      'Palghar',
      'Parbhani',
      'Pimpri Chinchwad',
      'Pune',
      'Pune City',
      'Pune Rural',
      'Raigad',
      'Ratnagiri',
      'Sangli',
      'Satara',
      'Sindhudurg',
      'Solapur',
      'Solapur City',
      'Solapur Rural',
      'Thane',
      'Thane City',
      'Thane Rural',
      'Wardha',
      'Washim',
      'Yavatmal',
    ],
    'Gujarat': [
      'Ahmedabad',
      'Amreli',
      'Anand',
      'Aravalli',
      'Banaskantha',
      'Bharuch',
      'Bhavnagar',
      'Botad',
      'Chhota Udaipur',
      'Dahod',
      'Dang',
      'Devbhoomi Dwarka',
      'Gandhinagar',
      'Gir Somnath',
      'Jamnagar',
      'Junagadh',
      'Kheda',
      'Kutch',
      'Mahisagar',
      'Mehsana',
      'Morbi',
      'Narmada',
      'Navsari',
      'Panchmahal',
      'Patan',
      'Porbandar',
      'Rajkot',
      'Sabarkantha',
      'Surat',
      'Surendranagar',
      'Tapi',
      'Vadodara',
      'Valsad',
    ],
    'Delhi': [
      'Central Delhi',
      'East Delhi',
      'New Delhi',
      'North Delhi',
      'North East Delhi',
      'North West Delhi',
      'Shahdara',
      'South Delhi',
      'South East Delhi',
      'South West Delhi',
      'West Delhi',
    ],
    'Madhya Pradesh': [
      'Bhopal',
      'Indore',
      'Gwalior',
      'Jabalpur',
      'Ujjain',
      'Rewa',
      'Sagar',
      'Satna',
      'Ratlam',
      'Chhindwara',
      'Dewas',
      'Morena',
      'Bhind',
      'Guna',
      'Shivpuri',
      'Vidisha',
    ],
    'Uttar Pradesh': [
      'Agra',
      'Aligarh',
      'Prayagraj',
      'Bareilly',
      'Ghaziabad',
      'Gorakhpur',
      'Jhansi',
      'Kanpur Nagar',
      'Lucknow',
      'Mathura',
      'Meerut',
      'Moradabad',
      'Noida (Gautam Buddha Nagar)',
      'Saharanpur',
      'Varanasi',
    ],
    'Karnataka': [
      'Bengaluru Urban',
      'Bengaluru Rural',
      'Mysuru',
      'Belagavi',
      'Mangaluru (Dakshina Kannada)',
      'Hubballi-Dharwad',
      'Kalaburagi',
      'Ballari',
      'Shivamogga',
      'Tumakuru',
      'Udupi',
    ],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Tirunelveli',
      'Tiruppur',
      'Erode',
      'Vellore',
      'Thoothukudi',
      'Kanchipuram',
    ],
    'Rajasthan': [
      'Jaipur',
      'Jodhpur',
      'Kota',
      'Bikaner',
      'Ajmer',
      'Udaipur',
      'Bhilwara',
      'Alwar',
      'Bharatpur',
      'Sikar',
      'Pali',
    ],
    'West Bengal': [
      'Kolkata',
      'Howrah',
      'North 24 Parganas',
      'South 24 Parganas',
      'Hooghly',
      'Darjeeling',
      'Siliguri',
      'Paschim Medinipur',
      'Purba Medinipur',
      'Murshidabad',
      'Nadia',
    ],
    'Telangana': [
      'Hyderabad',
      'Cyberabad',
      'Rachakonda',
      'Warangal',
      'Karimnagar',
      'Nizamabad',
      'Khammam',
      'Ramagundam',
      'Mahabubnagar',
      'Nalgonda',
    ],
    'Andhra Pradesh': [
      'Alluri Sitharama Raju',
      'Anakapalli',
      'Anantapur',
      'Annamayya',
      'Bapatla',
      'Chittoor',
      'East Godavari',
      'Eluru',
      'Guntur',
      'Kakinada',
      'Konaseema',
      'Krishna',
      'Kurnool',
      'Markapuram',
      'NTR',
      'Nandyal',
      'Palnadu',
      'Parvathipuram Manyam',
      'Polavaram',
      'Prakasam',
      'Sri Sathya Sai',
      'Srikakulam',
      'SPSR Nellore',
      'Tirupati',
      'Visakhapatnam',
      'Vizianagaram',
      'West Godavari',
      'YSR Kadapa (Kadapa)',
    ],
    'Kerala': [
      'Thiruvananthapuram',
      'Kochi (Ernakulam)',
      'Kozhikode',
      'Thrissur',
      'Kollam',
      'Kannur',
      'Alappuzha',
      'Palakkad',
      'Malappuram',
      'Kottayam',
    ],
    'Bihar': [
      'Patna',
      'Gaya',
      'Bhagalpur',
      'Muzaffarpur',
      'Purnia',
      'Darbhanga',
      'Bihar Sharif',
      'Arrah',
      'Begusarai',
      'Katihar',
    ],
    'Punjab': [
      'Amritsar',
      'Ludhiana',
      'Jalandhar',
      'Patiala',
      'Bathinda',
      'Mohali (SAS Nagar)',
      'Hoshiarpur',
      'Pathankot',
      'Moga',
    ],
    'Haryana': [
      'Gurugram',
      'Faridabad',
      'Panipat',
      'Ambala',
      'Rohtak',
      'Hisar',
      'Karnal',
      'Sonipat',
      'Panchkula',
    ],
    'Chhattisgarh': [
      'Raipur',
      'Bilaspur',
      'Durg',
      'Bhilai',
      'Balod',
      'Baloda Bazar',
      'Rajnandgaon',
      'Korba',
      'Jagdalpur (Bastar)',
      'Raigarh',
    ],
    'Jharkhand': [
      'Ranchi',
      'Jamshedpur (East Singhbhum)',
      'Dhanbad',
      'Bokaro',
      'Hazaribagh',
      'Deoghar',
      'Giridih',
      'Ramgarh',
    ],
    'Odisha': [
      'Bhubaneswar (Khurda)',
      'Cuttack',
      'Rourkela (Sundargarh)',
      'Berhampur (Ganjam)',
      'Sambalpur',
      'Puri',
      'Balasore',
      'Bhadrak',
    ],
    'Assam': [
      'Guwahati (Kamrup Metro)',
      'Dibrugarh',
      'Silchar (Cachar)',
      'Jorhat',
      'Nagaon',
      'Tinsukia',
      'Tezpur (Sonitpur)',
    ],
    'Goa': [
      'North Goa',
      'South Goa',
      'Panaji',
      'Margao',
      'Mapusa',
      'Vasco da Gama',
    ],
    'Uttarakhand': [
      'Dehradun',
      'Haridwar',
      'Nainital',
      'Udham Singh Nagar',
      'Rishikesh',
      'Roorkee',
      'Haldwani',
    ],
    'Himachal Pradesh': [
      'Shimla',
      'Kangra',
      'Mandi',
      'Solan',
      'Kullu',
      'Dharamshala',
      'Sirmaur',
    ],
    'Jammu and Kashmir': [
      'Srinagar',
      'Jammu',
      'Anantnag',
      'Baramulla',
      'Kathua',
      'Udhampur',
      'Budgam',
    ],
    'Ladakh': [
      'Leh',
      'Kargil',
    ],
    'Chandigarh': [
      'Chandigarh',
    ],
    'Puducherry': [
      'Puducherry',
      'Karaikal',
      'Mahe',
      'Yanam',
    ],
    'Arunachal Pradesh': [
      'Anjaw',
      'Bichom',
      'Changlang',
      'Dibang Valley',
      'East Kameng',
      'East Siang',
      'Kamle',
      'Keyi Panyor',
      'Kra Daadi',
      'Kurung Kumey',
      'Lepa-Rada',
      'Lohit',
      'Longding',
      'Lower Dibang Valley',
      'Lower Siang',
      'Lower Subansiri',
      'Namsai',
      'Pakke-Kessang',
      'Papum Pare',
      'Shi-Yomi',
      'Siang',
      'Tawang',
      'Tirap',
      'Upper Dibang Valley',
      'Upper Siang',
      'Upper Subansiri',
      'West Kameng',
      'West Siang',
    ],
    'Manipur': [
      'Imphal East',
      'Imphal West',
      'Thoubal',
      'Bishnupur',
      'Churachandpur',
    ],
    'Meghalaya': [
      'East Khasi Hills (Shillong)',
      'West Garo Hills (Tura)',
      'Ri-Bhoi',
      'West Jaintia Hills',
    ],
    'Mizoram': [
      'Aizawl',
      'Lunglei',
      'Champhai',
      'Kolasib',
    ],
    'Nagaland': [
      'Kohima',
      'Dimapur',
      'Mokokchung',
      'Tuensang',
      'Wokha',
    ],
    'Sikkim': [
      'Gangtok (East Sikkim)',
      'Namchi (South Sikkim)',
      'Geyzing (West Sikkim)',
      'Mangan (North Sikkim)',
    ],
    'Tripura': [
      'West Tripura (Agartala)',
      'Gomati',
      'North Tripura',
      'South Tripura',
      'Dhalai',
    ],
    'Andaman and Nicobar Islands': [
      'South Andaman (Port Blair)',
      'North and Middle Andaman',
      'Nicobar',
    ],
    'Dadra and Nagar Haveli and Daman and Diu': [
      'Daman',
      'Diu',
      'Dadra and Nagar Haveli (Silvassa)',
    ],
    'Lakshadweep': [
      'Kavaratti',
      'Agatti',
      'Andrott',
      'Minicoy',
    ],
  };

  /// Returns list of districts for the given state.
  static List<String> getDistrictsForState(String? state) {
    if (state == null || state == 'All States' || state.isEmpty) {
      // Return all unique districts across all states
      final set = <String>{};
      for (final list in stateDistrictsMap.values) {
        set.addAll(list);
      }
      final sorted = set.toList()..sort();
      return sorted;
    }

    final list = stateDistrictsMap[state];
    if (list != null && list.isNotEmpty) {
      final sorted = List<String>.from(list)..sort();
      return sorted;
    }

    return const [];
  }

  /// Returns list of police station names for a given district.
  static List<String> getStationsForDistrict(String? district) {
    if (district == null || district.isEmpty) return const [];
    final stations = stationsByDistrict[district];
    if (stations != null && stations.isNotEmpty) {
      return stations;
    }
    return [
      '$district Central PS',
      '$district North PS',
      '$district South PS',
      '$district Town PS',
    ];
  }

  /// Checks whether a user record belongs to an administrative account rather than an operational police officer.
  static bool isAdminUser(Map<String, dynamic> data) {
    final role = (data['role'] ?? '').toString().trim().toLowerCase();
    final email = (data['email'] ?? '').toString().trim().toLowerCase();
    final name = (data['name'] ?? data['fullName'] ?? '').toString().trim().toLowerCase();

    return role == 'admin' ||
        role == 'super_admin' ||
        role == 'superadmin' ||
        role == 'master_admin' ||
        role == 'super admin' ||
        role == 'master admin' ||
        data['isSuperAdmin'] == true ||
        email == 'master.admin@pms.gov.in' ||
        email == 'admin@police.gov.in' ||
        email == 'superadmin@police.gov.in' ||
        email.startsWith('admin@') ||
        name == 'master admin';
  }

  /// Checks whether a user document represents a pending officer registration request (excluding admin accounts).
  static bool isPendingApproval(Map<String, dynamic> data) {
    if (isAdminUser(data)) return false;
    final status = (data['accountStatus'] ?? data['status'] ?? 'pending').toString().toLowerCase();
    return status == 'pending_approval' || status == 'pending';
  }

  /// Checks whether a user document represents an approved active officer (excluding admin accounts).
  static bool isApprovedOfficer(Map<String, dynamic> data) {
    if (isAdminUser(data)) return false;
    final status = (data['accountStatus'] ?? data['status'] ?? 'active').toString().toLowerCase();
    return status == 'active' || status == 'approved';
  }

  /// Checks whether a user document represents a rejected registration request (excluding admin accounts).
  static bool isRejectedOfficer(Map<String, dynamic> data) {
    if (isAdminUser(data)) return false;
    final status = (data['accountStatus'] ?? data['status'] ?? '').toString().toLowerCase();
    return status == 'rejected';
  }
}
