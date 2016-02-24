import Foundation
import UIKit

@IBDesignable
class MRWeightView: UIView {
    
    private let label: UILabel = UILabel()
    private let image: UIImageView = UIImageView()
    
    private var lineWidth: CGFloat {
        return min(frame.width, frame.height) / 16
    }
    
    @IBInspectable
    var value: Double? {
        get { return _value }
        set(v) {
            _value = v.map { max(0, $0) }
            label.text = v.map { NSMassFormatter().stringFromKilograms($0) } ?? nil
        }
    }
    
    var _value: Double? = nil
    
    var font: UIFont = UIFont.systemFontOfSize(17) {
        didSet {
            label.font = font
        }
    }
    
    private var fontSize: CGFloat {
        guard let text = label.text else { return label.font.pointSize }
        let font = label.font
        var fontSize = frame.height / 2.5
        var size = text.sizeWithAttributes([NSFontAttributeName: font.fontWithSize(fontSize)])
        while (size.width > bounds.width - 8 * lineWidth) {
            fontSize -= 1
            size = text.sizeWithAttributes([NSFontAttributeName: font.fontWithSize(fontSize)])
        }
        return fontSize
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI()
    }
    
    private func createUI() {
        self.backgroundColor = UIColor.orangeColor()
        image.image = UIImage(named: "weight")
        image.contentMode = .ScaleAspectFit
        addSubview(image)
        addSubview(label)
    }
    
    override func drawRect(rect: CGRect) {
        let shift = min(frame.width, frame.height) / 4
        label.frame = CGRectMake(0, shift, frame.width, frame.height - shift)
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        label.font = label.font.fontWithSize(fontSize)
        image.frame = self.bounds
    }
    
}
