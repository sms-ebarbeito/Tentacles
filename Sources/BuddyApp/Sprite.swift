import CoreGraphics

// Un frame del sprite sheet con su punto de anclaje del pie.
// ax: offset x del pie desde el centro del rect (px del PNG, + = derecha)
// ay: offset y del pie desde el borde inferior del rect (px del PNG, + = arriba)
struct SpriteFrame {
    let rect: CGRect
    let ax: CGFloat
    let ay: CGFloat

    init(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
         ax: CGFloat = 0, ay: CGFloat = 0) {
        rect = CGRect(x: x, y: y, width: w, height: h)
        self.ax = ax
        self.ay = ay
    }
}

enum Sprite {
    static let displaySize = CGSize(width: 160, height: 200)
    static let scale: CGFloat = 1.5

    // El pie siempre se ancla a este y desde el fondo de la ventana (puntos de pantalla)
    // = max(ay) * scale = 16 * 1.5 = 24
    static let groundLevel: CGFloat = 24

    // Idle: band_00
    static let idle: [SpriteFrame] = [
        SpriteFrame( 2, 11, 34, 56, ax:  0, ay: 6),
        SpriteFrame(45, 11, 34, 56, ax:  0, ay: 6),
        SpriteFrame(84, 11, 34, 56, ax:  0, ay: 7),
        SpriteFrame(45, 11, 34, 56, ax:  0, ay: 6),
    ]

    // Alert: band_07, 16 frames con lengua
    static let alert: [SpriteFrame] = [
        SpriteFrame(  0, 613,  34,  51, ax:  1, ay:  6),
        SpriteFrame( 34, 609,  43,  55, ax:  5, ay:  6),
        SpriteFrame( 77, 608,  44,  56, ax:  5, ay:  5),
        SpriteFrame(121, 621,  45,  43, ax:  6, ay:  5),
        SpriteFrame(166, 632,  44,  32, ax:  5, ay:  4),
        SpriteFrame(210, 631,  48,  33, ax:  7, ay:  4),
        SpriteFrame(258, 623,  44,  41, ax:  6, ay:  5),
        SpriteFrame(302, 622,  46,  42, ax:  6, ay:  5),
        SpriteFrame(348, 613,  43,  51, ax:  5, ay:  6),
        SpriteFrame(391, 596,  49,  68, ax:  8, ay:  7),
        SpriteFrame(440, 592,  45,  72, ax:  6, ay:  6),
        SpriteFrame(485, 634,  62,  30, ax:  6, ay:  5),
        SpriteFrame(547, 639,  66,  25, ax:  5, ay:  5),
        SpriteFrame(613, 634,  58,  30, ax:  4, ay:  4),
        SpriteFrame(671, 563,  68, 101, ax: -6, ay: 12),
        SpriteFrame(739, 563,  48, 101, ax: -7, ay: 12),
    ]

    // Alert continuación: band_09 (10 frames)
    static let alert2: [SpriteFrame] = [
        SpriteFrame(  0, 771,  70,  92, ax:  4, ay: 15),
        SpriteFrame( 78, 765,  72,  98, ax:  2, ay: 16),
        SpriteFrame(151, 808,  49,  55, ax: -5, ay:  6),
        SpriteFrame(200, 828,  50,  35, ax: -2, ay:  5),
        SpriteFrame(250, 841,  70,  22, ax:  4, ay:  4),
        SpriteFrame(320, 823,  80,  40, ax: 10, ay:  6),
        SpriteFrame(410, 800,  90,  63, ax: 19, ay:  6),
        SpriteFrame(500, 798,  80,  65, ax: 10, ay:  7),
        SpriteFrame(580, 822,  90,  41, ax:  7, ay:  5),
        SpriteFrame(670, 830,  80,  33, ax:  1, ay:  4),
    ]

    // Alert continuación: band_10 (14 frames)
    static let alert3: [SpriteFrame] = [
        SpriteFrame(  2, 920,  71,  30, ax:  1, ay:  4),
        SpriteFrame( 85, 926,  73,  24, ax:  1, ay:  5),
        SpriteFrame(169, 909,  49,  41, ax:  0, ay: 10),
        SpriteFrame(230, 878,  33,  72, ax:  0, ay:  6),
        SpriteFrame(275, 914,  39,  36, ax:  0, ay:  5),
        SpriteFrame(327, 917,  43,  33, ax: -2, ay:  5),
        SpriteFrame(380, 914,  39,  36, ax: -1, ay:  5),
        SpriteFrame(429, 894,  33,  56, ax:  0, ay:  7),
        SpriteFrame(472, 899,  32,  51, ax:  0, ay:  6),
        SpriteFrame(514, 919,  34,  31, ax:  0, ay:  4),
        SpriteFrame(558, 921,  36,  29, ax:  0, ay:  4),
        SpriteFrame(606, 920,  41,  30, ax:  0, ay:  4),
        SpriteFrame(659, 919,  45,  31, ax:  0, ay:  5),
        SpriteFrame(718, 915,  52,  35, ax:  0, ay:  4),
    ]

    // Alert continuación: band_11 (10 frames)
    static let alert4: [SpriteFrame] = [
        SpriteFrame(  1, 1019,  64,  32, ax: -3, ay:  4),
        SpriteFrame( 65, 1016,  73,  35, ax:  0, ay:  5),
        SpriteFrame(138, 1017,  79,  34, ax: -3, ay:  4),
        SpriteFrame(217, 1005,  89,  46, ax: -2, ay:  3),
        SpriteFrame(306, 1019,  88,  32, ax: -3, ay:  5),
        SpriteFrame(394, 1017,  82,  34, ax:  0, ay:  6),
        SpriteFrame(476, 1018,  85,  33, ax:  2, ay:  5),
        SpriteFrame(561, 1019,  88,  32, ax: -2, ay:  5),
        SpriteFrame(649, 1010,  84,  41, ax: -3, ay:  5),
        SpriteFrame(733, 1000,  65,  51, ax:  0, ay:  6),
    ]

    // Crazy: band_08 (11 frames)
    static let crazy: [SpriteFrame] = [
        SpriteFrame(  2, 664,  40,  97, ax:  0, ay: 14),
        SpriteFrame( 52, 664,  45,  97, ax:  1, ay: 10),
        SpriteFrame(108, 664,  43,  97, ax: -4, ay:  8),
        SpriteFrame(164, 664,  40,  97, ax: -1, ay: 11),
        SpriteFrame(221, 664,  85,  97, ax:-12, ay: 14),
        SpriteFrame(322, 664,  80,  97, ax:-10, ay: 15),
        SpriteFrame(425, 664,  44,  97, ax:  0, ay: 14),
        SpriteFrame(480, 664,  50,  97, ax:  0, ay:  9),
        SpriteFrame(539, 664,  36,  97, ax:  1, ay: 11),
        SpriteFrame(587, 664,  35,  97, ax: -1, ay: 14),
        SpriteFrame(643, 664,  36,  97, ax:  0, ay: 14),
    ]

    // Squish: band_04 (no usado en animaciones)
    static let squish = CGRect(x: 2, y: 315, width: 23, height: 17)
}
