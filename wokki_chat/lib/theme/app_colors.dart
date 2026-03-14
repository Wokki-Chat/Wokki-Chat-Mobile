import 'package:flutter/material.dart';

class AppColors {
  final Color darkA0;
  final Color lightA0;
  
  final Color primaryA0;
  final Color primaryA10;
  final Color primaryA20;
  final Color primaryA30;
  final Color primaryA40;
  final Color primaryA50;
  
  final Color surfaceA0;
  final Color surfaceA10;
  final Color surfaceA20;
  final Color surfaceA30;
  final Color surfaceA40;
  final Color surfaceA50;
  
  final Color surfaceTonalA0;
  final Color surfaceTonalA10;
  final Color surfaceTonalA20;
  final Color surfaceTonalA30;
  final Color surfaceTonalA40;
  final Color surfaceTonalA50;
  
  final Color secondaryA0;
  final Color secondaryA10;
  final Color secondaryA20;
  final Color secondaryA30;
  final Color secondaryA40;
  final Color secondaryA50;
  
  final Color inputBgDarkest;
  final Color inputBgDark;
  final Color inputBorderBgDarkest;
  final Color inputBorderBgDark;
  
  final Color popupA0;
  final Color popupA10;
  final Color popupA20;
  final Color popupA30;
  final Color popupA40;
  final Color popupA50;
  
  final Color textA0;
  final Color textA10;
  final Color textA20;
  final Color textA30;
  final Color textA40;
  final Color textA50;
  
  final Color textWhiteA0;
  final Color textWhiteA10;
  final Color textWhiteA20;
  final Color textWhiteA30;
  final Color textWhiteA40;
  final Color textWhiteA50;
  
  final Color textBlackA0;
  final Color textBlackA10;
  final Color textBlackA20;
  final Color textBlackA30;
  final Color textBlackA40;
  final Color textBlackA50;
  
  final Color errorA0;
  
  final Color statusOnline;
  final Color statusOffline;
  final Color statusBusy;
  final Color statusIdle;
  
  final Color danger;
  
  final Color successA0;
  final Color successA10;
  final Color successA20;
  
  final Color warningA0;
  final Color warningA10;
  final Color warningA20;
  
  final Color dangerA0;
  final Color dangerA10;
  final Color dangerA20;
  
  final Color infoA0;
  final Color infoA10;
  final Color infoA20;

  const AppColors({
    required this.darkA0,
    required this.lightA0,
    required this.primaryA0,
    required this.primaryA10,
    required this.primaryA20,
    required this.primaryA30,
    required this.primaryA40,
    required this.primaryA50,
    required this.surfaceA0,
    required this.surfaceA10,
    required this.surfaceA20,
    required this.surfaceA30,
    required this.surfaceA40,
    required this.surfaceA50,
    required this.surfaceTonalA0,
    required this.surfaceTonalA10,
    required this.surfaceTonalA20,
    required this.surfaceTonalA30,
    required this.surfaceTonalA40,
    required this.surfaceTonalA50,
    required this.secondaryA0,
    required this.secondaryA10,
    required this.secondaryA20,
    required this.secondaryA30,
    required this.secondaryA40,
    required this.secondaryA50,
    required this.inputBgDarkest,
    required this.inputBgDark,
    required this.inputBorderBgDarkest,
    required this.inputBorderBgDark,
    required this.popupA0,
    required this.popupA10,
    required this.popupA20,
    required this.popupA30,
    required this.popupA40,
    required this.popupA50,
    required this.textA0,
    required this.textA10,
    required this.textA20,
    required this.textA30,
    required this.textA40,
    required this.textA50,
    required this.textWhiteA0,
    required this.textWhiteA10,
    required this.textWhiteA20,
    required this.textWhiteA30,
    required this.textWhiteA40,
    required this.textWhiteA50,
    required this.textBlackA0,
    required this.textBlackA10,
    required this.textBlackA20,
    required this.textBlackA30,
    required this.textBlackA40,
    required this.textBlackA50,
    required this.errorA0,
    required this.statusOnline,
    required this.statusOffline,
    required this.statusBusy,
    required this.statusIdle,
    required this.danger,
    required this.successA0,
    required this.successA10,
    required this.successA20,
    required this.warningA0,
    required this.warningA10,
    required this.warningA20,
    required this.dangerA0,
    required this.dangerA10,
    required this.dangerA20,
    required this.infoA0,
    required this.infoA10,
    required this.infoA20,
  });

  static const light = AppColors(
    darkA0: Color(0xFF000000),
    lightA0: Color(0xFFFFFFFF),
    primaryA0: Color(0xFF895BF5),
    primaryA10: Color(0xFF996DF7),
    primaryA20: Color(0xFFA87FF8),
    primaryA30: Color(0xFFB691FA),
    primaryA40: Color(0xFFC3A3FB),
    primaryA50: Color(0xFFD0B5FC),
    surfaceA0: Color(0xFFFFFFFF),
    surfaceA10: Color(0xFFF2F2F2),
    surfaceA20: Color(0xFFE5E5E5),
    surfaceA30: Color(0xFFD9D9D9),
    surfaceA40: Color(0xFFCCCCCC),
    surfaceA50: Color(0xFFBFBFBF),
    surfaceTonalA0: Color(0xFFF5F2F7),
    surfaceTonalA10: Color(0xFFEAE6ED),
    surfaceTonalA20: Color(0xFFDFDAE4),
    surfaceTonalA30: Color(0xFFD4D0DB),
    surfaceTonalA40: Color(0xFFC9C5D2),
    surfaceTonalA50: Color(0xFFBEBACF),
    secondaryA0: Color(0xFF2CD4BD),
    secondaryA10: Color(0xFF55D9C4),
    secondaryA20: Color(0xFF71DECB),
    secondaryA30: Color(0xFF89E3D3),
    secondaryA40: Color(0xFF9FE8DA),
    secondaryA50: Color(0xFFB4EDE1),
    inputBgDarkest: Color(0xFFF5F5F5),
    inputBgDark: Color(0xFFE0E0E0),
    inputBorderBgDarkest: Color(0xFFCCCCCC),
    inputBorderBgDark: Color(0xFFF7F7F7),
    popupA0: Color(0xFFF0F0F0),
    popupA10: Color(0xFFE0E0E0),
    popupA20: Color(0xFFD1D1D1),
    popupA30: Color(0xFFC2C2C2),
    popupA40: Color(0xFFB3B3B3),
    popupA50: Color(0xFFA4A4A4),
    textA0: Color(0xFF000000),
    textA10: Color(0xFF1A1A1A),
    textA20: Color(0xFF333333),
    textA30: Color(0xFF4D4D4D),
    textA40: Color(0xFF666666),
    textA50: Color(0xFF808080),
    textWhiteA0: Color(0xFFFFFFFF),
    textWhiteA10: Color(0xFFE0E0E0),
    textWhiteA20: Color(0xFFC4C4C4),
    textWhiteA30: Color(0xFFB2B2B2),
    textWhiteA40: Color(0xFF8C8C8C),
    textWhiteA50: Color(0xFF707070),
    textBlackA0: Color(0xFF000000),
    textBlackA10: Color(0xFF1A1A1A),
    textBlackA20: Color(0xFF333333),
    textBlackA30: Color(0xFF4D4D4D),
    textBlackA40: Color(0xFF666666),
    textBlackA50: Color(0xFF808080),
    errorA0: Color(0x7EFF0000),
    statusOnline: Color(0xFF68C25C),
    statusOffline: Color(0xFF686868),
    statusBusy: Color(0xFFBA3939),
    statusIdle: Color(0xFFFFCD43),
    danger: Color(0xFFFF7C7C),
    successA0: Color(0xFF1B7F5C),
    successA10: Color(0xFF28BE8A),
    successA20: Color(0xFF58DBAD),
    warningA0: Color(0xFFB8871F),
    warningA10: Color(0xFFDFAE44),
    warningA20: Color(0xFFEBCA85),
    dangerA0: Color(0xFFB13535),
    dangerA10: Color(0xFFD06262),
    dangerA20: Color(0xFFE29D9D),
    infoA0: Color(0xFF1E56A3),
    infoA10: Color(0xFF347ADA),
    infoA20: Color(0xFF74A4E6),
  );

  static const slate = AppColors(
    darkA0: Color(0xFF000000),
    lightA0: Color(0xFFFFFFFF),
    primaryA0: Color(0xFF895BF5),
    primaryA10: Color(0xFF996DF7),
    primaryA20: Color(0xFFA87FF8),
    primaryA30: Color(0xFFB691FA),
    primaryA40: Color(0xFFC3A3FB),
    primaryA50: Color(0xFFD0B5FC),
    surfaceA0: Color(0xFF1F1F1F),
    surfaceA10: Color(0xFF343434),
    surfaceA20: Color(0xFF4A4A4A),
    surfaceA30: Color(0xFF5E5E5E),
    surfaceA40: Color(0xFF797979),
    surfaceA50: Color(0xFF939393),
    surfaceTonalA0: Color(0xFF2A2531),
    surfaceTonalA10: Color(0xFF3E3945),
    surfaceTonalA20: Color(0xFF544F5A),
    surfaceTonalA30: Color(0xFF6A666F),
    surfaceTonalA40: Color(0xFF817E86),
    surfaceTonalA50: Color(0xFF99969D),
    secondaryA0: Color(0xFF2CD4BD),
    secondaryA10: Color(0xFF55D9C4),
    secondaryA20: Color(0xFF71DECB),
    secondaryA30: Color(0xFF89E3D3),
    secondaryA40: Color(0xFF9FE8DA),
    secondaryA50: Color(0xFFB4EDE1),
    inputBgDarkest: Color(0xFF141414),
    inputBgDark: Color(0xFF323232),
    inputBorderBgDarkest: Color(0xFF3B3B3B),
    inputBorderBgDark: Color(0xFF282828),
    popupA0: Color(0xFF303030),
    popupA10: Color(0xFF404040),
    popupA20: Color(0xFF505050),
    popupA30: Color(0xFF616161),
    popupA40: Color(0xFF727272),
    popupA50: Color(0xFF838383),
    textA0: Color(0xFFDFDFDF),
    textA10: Color(0xFFE0E0E0),
    textA20: Color(0xFFC4C4C4),
    textA30: Color(0xFFB2B2B2),
    textA40: Color(0xFF8C8C8C),
    textA50: Color(0xFF707070),
    textWhiteA0: Color(0xFFFFFFFF),
    textWhiteA10: Color(0xFFE0E0E0),
    textWhiteA20: Color(0xFFC4C4C4),
    textWhiteA30: Color(0xFFB2B2B2),
    textWhiteA40: Color(0xFF8C8C8C),
    textWhiteA50: Color(0xFF707070),
    textBlackA0: Color(0xFF000000),
    textBlackA10: Color(0xFF1A1A1A),
    textBlackA20: Color(0xFF333333),
    textBlackA30: Color(0xFF4D4D4D),
    textBlackA40: Color(0xFF666666),
    textBlackA50: Color(0xFF808080),
    errorA0: Color(0x7EFF0000),
    statusOnline: Color(0xFF68C25C),
    statusOffline: Color(0xFF686868),
    statusBusy: Color(0xFFBA3939),
    statusIdle: Color(0xFFFFCD43),
    danger: Color(0xFFFF7C7C),
    successA0: Color(0xFF22946E),
    successA10: Color(0xFF47D5A6),
    successA20: Color(0xFF9AE8CE),
    warningA0: Color(0xFFA87A2A),
    warningA10: Color(0xFFD7AC61),
    warningA20: Color(0xFFECD7B2),
    dangerA0: Color(0xFF9C2121),
    dangerA10: Color(0xFFD94A4A),
    dangerA20: Color(0xFFEB9E9E),
    infoA0: Color(0xFF21498A),
    infoA10: Color(0xFF4077D1),
    infoA20: Color(0xFF92B2E5),
  );

  static const owl = AppColors(
    darkA0: Color(0xFF000000),
    lightA0: Color(0xFFFFFFFF),
    primaryA0: Color(0xFF895BF5),
    primaryA10: Color(0xFF996DF7),
    primaryA20: Color(0xFFA87FF8),
    primaryA30: Color(0xFFB691FA),
    primaryA40: Color(0xFFC3A3FB),
    primaryA50: Color(0xFFD0B5FC),
    surfaceA0: Color(0xFF101010),
    surfaceA10: Color(0xFF1C1C1C),
    surfaceA20: Color(0xFF2A2A2A),
    surfaceA30: Color(0xFF383838),
    surfaceA40: Color(0xFF4A4A4A),
    surfaceA50: Color(0xFF5C5C5C),
    surfaceTonalA0: Color(0xFF1C1822),
    surfaceTonalA10: Color(0xFF2D2934),
    surfaceTonalA20: Color(0xFF3F3B45),
    surfaceTonalA30: Color(0xFF525056),
    surfaceTonalA40: Color(0xFF65626A),
    surfaceTonalA50: Color(0xFF79757E),
    secondaryA0: Color(0xFF2CD4BD),
    secondaryA10: Color(0xFF55D9C4),
    secondaryA20: Color(0xFF71DECB),
    secondaryA30: Color(0xFF89E3D3),
    secondaryA40: Color(0xFF9FE8DA),
    secondaryA50: Color(0xFFB4EDE1),
    inputBgDarkest: Color(0xFF0C0C0C),
    inputBgDark: Color(0xFF1F1F1F),
    inputBorderBgDarkest: Color(0xFF1A1A1A),
    inputBorderBgDark: Color(0xFF292929),
    popupA0: Color(0xFF181818),
    popupA10: Color(0xFF222222),
    popupA20: Color(0xFF2E2E2E),
    popupA30: Color(0xFF3A3A3A),
    popupA40: Color(0xFF474747),
    popupA50: Color(0xFF555555),
    textA0: Color(0xFFDFDFDF),
    textA10: Color(0xFFE0E0E0),
    textA20: Color(0xFFC4C4C4),
    textA30: Color(0xFFB2B2B2),
    textA40: Color(0xFF8C8C8C),
    textA50: Color(0xFF707070),
    textWhiteA0: Color(0xFFFFFFFF),
    textWhiteA10: Color(0xFFE0E0E0),
    textWhiteA20: Color(0xFFC4C4C4),
    textWhiteA30: Color(0xFFB2B2B2),
    textWhiteA40: Color(0xFF8C8C8C),
    textWhiteA50: Color(0xFF707070),
    textBlackA0: Color(0xFF000000),
    textBlackA10: Color(0xFF1A1A1A),
    textBlackA20: Color(0xFF333333),
    textBlackA30: Color(0xFF4D4D4D),
    textBlackA40: Color(0xFF666666),
    textBlackA50: Color(0xFF808080),
    errorA0: Color(0x7EFF0000),
    statusOnline: Color(0xFF68C25C),
    statusOffline: Color(0xFF686868),
    statusBusy: Color(0xFFBA3939),
    statusIdle: Color(0xFFFFCD43),
    danger: Color(0xFFFF7C7C),
    successA0: Color(0xFF22946E),
    successA10: Color(0xFF47D5A6),
    successA20: Color(0xFF9AE8CE),
    warningA0: Color(0xFFA87A2A),
    warningA10: Color(0xFFD7AC61),
    warningA20: Color(0xFFECD7B2),
    dangerA0: Color(0xFF9C2121),
    dangerA10: Color(0xFFD94A4A),
    dangerA20: Color(0xFFEB9E9E),
    infoA0: Color(0xFF21498A),
    infoA10: Color(0xFF4077D1),
    infoA20: Color(0xFF92B2E5),
  );

  static const midnight = AppColors(
    darkA0: Color(0xFF000000),
    lightA0: Color(0xFFFFFFFF),
    primaryA0: Color(0xFF895BF5),
    primaryA10: Color(0xFF996DF7),
    primaryA20: Color(0xFFA87FF8),
    primaryA30: Color(0xFFB691FA),
    primaryA40: Color(0xFFC3A3FB),
    primaryA50: Color(0xFFD0B5FC),
    surfaceA0: Color(0xFF050505),
    surfaceA10: Color(0xFF202020),
    surfaceA20: Color(0xFF373737),
    surfaceA30: Color(0xFF515151),
    surfaceA40: Color(0xFF6B6B6B),
    surfaceA50: Color(0xFF878787),
    surfaceTonalA0: Color(0xFF17121E),
    surfaceTonalA10: Color(0xFF2C2833),
    surfaceTonalA20: Color(0xFF433F49),
    surfaceTonalA30: Color(0xFF5B5760),
    surfaceTonalA40: Color(0xFF747179),
    surfaceTonalA50: Color(0xFF8E8B92),
    secondaryA0: Color(0xFF2CD4BD),
    secondaryA10: Color(0xFF55D9C4),
    secondaryA20: Color(0xFF71DECB),
    secondaryA30: Color(0xFF89E3D3),
    secondaryA40: Color(0xFF9FE8DA),
    secondaryA50: Color(0xFFB4EDE1),
    inputBgDarkest: Color(0xFF0C0C0C),
    inputBgDark: Color(0xFF161616),
    inputBorderBgDarkest: Color(0xFF1A1A1A),
    inputBorderBgDark: Color(0xFF222222),
    popupA0: Color(0xFF0A0A0A),
    popupA10: Color(0xFF141414),
    popupA20: Color(0xFF1E1E1E),
    popupA30: Color(0xFF282828),
    popupA40: Color(0xFF323232),
    popupA50: Color(0xFF3C3C3C),
    textA0: Color(0xFFDFDFDF),
    textA10: Color(0xFFE0E0E0),
    textA20: Color(0xFFC4C4C4),
    textA30: Color(0xFFB2B2B2),
    textA40: Color(0xFF8C8C8C),
    textA50: Color(0xFF707070),
    textWhiteA0: Color(0xFFFFFFFF),
    textWhiteA10: Color(0xFFE0E0E0),
    textWhiteA20: Color(0xFFC4C4C4),
    textWhiteA30: Color(0xFFB2B2B2),
    textWhiteA40: Color(0xFF8C8C8C),
    textWhiteA50: Color(0xFF707070),
    textBlackA0: Color(0xFF000000),
    textBlackA10: Color(0xFF1A1A1A),
    textBlackA20: Color(0xFF333333),
    textBlackA30: Color(0xFF4D4D4D),
    textBlackA40: Color(0xFF666666),
    textBlackA50: Color(0xFF808080),
    errorA0: Color(0x7EFF0000),
    statusOnline: Color(0xFF68C25C),
    statusOffline: Color(0xFF686868),
    statusBusy: Color(0xFFBA3939),
    statusIdle: Color(0xFFFFCD43),
    danger: Color(0xFFFF7C7C),
    successA0: Color(0xFF22946E),
    successA10: Color(0xFF47D5A6),
    successA20: Color(0xFF9AE8CE),
    warningA0: Color(0xFFA87A2A),
    warningA10: Color(0xFFD7AC61),
    warningA20: Color(0xFFECD7B2),
    dangerA0: Color(0xFF9C2121),
    dangerA10: Color(0xFFD94A4A),
    dangerA20: Color(0xFFEB9E9E),
    infoA0: Color(0xFF21498A),
    infoA10: Color(0xFF4077D1),
    infoA20: Color(0xFF92B2E5),
  );
}