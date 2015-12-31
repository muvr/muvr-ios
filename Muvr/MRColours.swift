import UIKit

///
/// Contains app-wide colours; consequently, there should be no colour constant 
/// anywhere in the source code outside of this struct.
///
/// When making changed here, be sure to update the UI Sketch!
///
struct MRColours {
    
    ///
    /// Constructs colour from its hex (the usual webby #84D60F) representaion
    /// - parameter hex: the RGB values
    /// - returns: the UIColour
    ///
    private static func colourFromHex(hex: UInt32) -> UIColor {
        let r = CGFloat((hex >> 16) & 0xFF)
        let g = CGFloat((hex >> 8) & 0xFF)
        let b = CGFloat((hex) & 0xFF)
        let tff = CGFloat(255)
        return UIColor(red: r / tff, green: g / tff, blue: b / tff, alpha: 1)
    }
    
    /// basic green colour
    static let green = MRColours.colourFromHex(0x57D041)
    /// light green colour; readable on ``green``
    static let lightGreen = MRColours.colourFromHex(0xCFF3CC)
    
    /// basic amber colour
    static let amber = MRColours.colourFromHex(0xFBC40C)
    /// light amber colour; readable on ``amber``
    static let lightAmber = MRColours.colourFromHex(0xFFFCD0)
    
    /// basic red colour
    static let red = MRColours.colourFromHex(0xD04141)
    /// light red colour; redable on ``red``
    static let lightRed = MRColours.colourFromHex(0xFEDDE1)
}

///
/// Defines a colour scheme
///
struct MRColourScheme {
    let tint: UIColor
    let light: UIColor
    let background: UIColor
}

///
/// Defines the basic colour schemes
///
struct MRColourSchemes {
    static let green = MRColourScheme(tint: MRColours.lightGreen, light: MRColours.lightGreen, background: MRColours.green)
    static let amber = MRColourScheme(tint: MRColours.lightAmber, light: MRColours.lightAmber, background: MRColours.amber)
}

