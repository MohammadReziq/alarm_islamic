class AdhanSound {
  final String id;
  final String name;
  final String sheikhName;
  final String assetPath;
  final bool isPro;

  const AdhanSound({
    required this.id,
    required this.name,
    required this.sheikhName,
    required this.assetPath,
    this.isPro = false,
  });
}

class SoundLibrary {
  static const List<AdhanSound> availableSounds = [
    AdhanSound(
      id: 'makkah',
      name: 'أذان مكة المكرمة',
      sheikhName: 'الحرم المكي',
      assetPath: 'assets/sounds/alarms_sound/makkah.mp3',
    ),
    AdhanSound(
      id: 'mansoor',
      name: 'أذان هادئ',
      sheikhName: 'الشيخ منصور الزهراني',
      assetPath: 'assets/sounds/alarms_sound/mansoor.mp3',
    ),
    AdhanSound(
      id: 'alafasy',
      name: 'أذان العفاسي',
      sheikhName: 'الشيخ مشاري العفاسي',
      assetPath: 'assets/sounds/alarms_sound/alafasy.mp3',
    ),
    AdhanSound(
      id: 'nasser',
      name: 'أذان حزين',
      sheikhName: 'الشيخ ناصر القطامي',
      assetPath: 'assets/sounds/alarms_sound/nasser.mp3',
    ),
    AdhanSound(
      id: 'refat',
      name: 'أذان مصري',
      sheikhName: 'الشيخ محمد رفعت',
      assetPath: 'assets/sounds/alarms_sound/refat.mp3',
    ),
    AdhanSound(
      id: 'ma3roof',
      name: 'أذان مميز',
      sheikhName: 'الشيخ معروف الشريف',
      assetPath: 'assets/sounds/alarms_sound/ma3roof.mp3',
    ),
  ];

  static AdhanSound getSoundById(String id) {
    return availableSounds.firstWhere(
      (s) => s.id == id,
      orElse: () => availableSounds.first,
    );
  }
    
  static AdhanSound getSoundByPath(String path) {
    return availableSounds.firstWhere(
        (s) => s.assetPath == path,
        orElse: () => availableSounds.first,
    );
  }
}
