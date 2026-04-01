import CoreGraphics

enum Sprite {
    // Ventana: suficientemente grande para el sprite más alto (crazy ~98px * 2x = 196px)
    static let displaySize = CGSize(width: 160, height: 200)
    static let scale: CGFloat = 1.5

    // Coordenadas exactas en el PNG (y=0 = parte superior)

    // Idle: band_00, criatura de pie
    static let idle: [CGRect] = [
        CGRect(x: 2,  y: 11, width: 34, height: 56),
        CGRect(x: 45, y: 11, width: 34, height: 56),
        CGRect(x: 84, y: 11, width: 34, height: 56),
        CGRect(x: 45, y: 11, width: 34, height: 56),
    ]

    // Alert: band_07 fila inferior, 16 frames con lengua
    static let alert: [CGRect] = [
        CGRect(x:   0, y: 613, width:  34, height:  51),
        CGRect(x:  34, y: 609, width:  43, height:  55),
        CGRect(x:  77, y: 608, width:  44, height:  56),
        CGRect(x: 121, y: 621, width:  45, height:  43),
        CGRect(x: 166, y: 632, width:  44, height:  32),
        CGRect(x: 210, y: 631, width:  48, height:  33),
        CGRect(x: 258, y: 623, width:  44, height:  41),
        CGRect(x: 302, y: 622, width:  46, height:  42),
        CGRect(x: 348, y: 613, width:  43, height:  51),
        CGRect(x: 391, y: 596, width:  49, height:  68),
        CGRect(x: 440, y: 592, width:  45, height:  72),
        CGRect(x: 485, y: 634, width:  62, height:  30),
        CGRect(x: 547, y: 639, width:  66, height:  25),
        CGRect(x: 613, y: 634, width:  58, height:  30),
        CGRect(x: 671, y: 563, width:  68, height: 101),
        CGRect(x: 739, y: 563, width:  48, height: 101),
    ]

    // Alert continuación: band_09 (10 frames)
    static let alert2: [CGRect] = [
        CGRect(x:   0, y: 771, width:  70, height:  92),
        CGRect(x:  78, y: 765, width:  72, height:  98),
        CGRect(x: 151, y: 808, width:  49, height:  55),
        CGRect(x: 200, y: 828, width:  50, height:  35),
        CGRect(x: 250, y: 841, width:  70, height:  22),
        CGRect(x: 320, y: 823, width:  80, height:  40),
        CGRect(x: 410, y: 800, width:  90, height:  63),
        CGRect(x: 500, y: 798, width:  80, height:  65),
        CGRect(x: 580, y: 822, width:  90, height:  41),
        CGRect(x: 670, y: 830, width:  80, height:  33),
    ]

    // Alert continuación: band_10 (14 frames)
    static let alert3: [CGRect] = [
        CGRect(x:   2, y: 920, width:  71, height:  30),
        CGRect(x:  85, y: 926, width:  73, height:  24),
        CGRect(x: 169, y: 909, width:  49, height:  41),
        CGRect(x: 230, y: 878, width:  33, height:  72),
        CGRect(x: 275, y: 914, width:  39, height:  36),
        CGRect(x: 327, y: 917, width:  43, height:  33),
        CGRect(x: 380, y: 914, width:  39, height:  36),
        CGRect(x: 429, y: 894, width:  33, height:  56),
        CGRect(x: 472, y: 899, width:  32, height:  51),
        CGRect(x: 514, y: 919, width:  34, height:  31),
        CGRect(x: 558, y: 921, width:  36, height:  29),
        CGRect(x: 606, y: 920, width:  41, height:  30),
        CGRect(x: 659, y: 919, width:  45, height:  31),
        CGRect(x: 718, y: 915, width:  52, height:  35),
    ]

    // Alert continuación: band_11 (10 frames)
    static let alert4: [CGRect] = [
        CGRect(x:   1, y:1019, width:  64, height:  32),
        CGRect(x:  65, y:1016, width:  73, height:  35),
        CGRect(x: 138, y:1017, width:  79, height:  34),
        CGRect(x: 217, y:1005, width:  89, height:  46),
        CGRect(x: 306, y:1019, width:  88, height:  32),
        CGRect(x: 394, y:1017, width:  82, height:  34),
        CGRect(x: 476, y:1018, width:  85, height:  33),
        CGRect(x: 561, y:1019, width:  88, height:  32),
        CGRect(x: 649, y:1010, width:  84, height:  41),
        CGRect(x: 733, y:1000, width:  65, height:  51),
    ]

    // Squish: band_04, aplastado
    static let squish = CGRect(x: 2, y: 315, width: 23, height: 17)

    // Crazy: band_08, animación completa (11 frames)
    static let crazy: [CGRect] = [
        CGRect(x: 2,   y: 664, width: 40, height: 97),
        CGRect(x: 52,  y: 664, width: 45, height: 97),
        CGRect(x: 108, y: 664, width: 43, height: 97),
        CGRect(x: 164, y: 664, width: 40, height: 97),
        CGRect(x: 221, y: 664, width: 85, height: 97),
        CGRect(x: 322, y: 664, width: 80, height: 97),
        CGRect(x: 425, y: 664, width: 44, height: 97),
        CGRect(x: 480, y: 664, width: 50, height: 97),
        CGRect(x: 539, y: 664, width: 36, height: 97),
        CGRect(x: 587, y: 664, width: 35, height: 97),
        CGRect(x: 643, y: 664, width: 36, height: 97),
    ]
}
