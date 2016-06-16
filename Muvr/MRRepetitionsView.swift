import Foundation
import UIKit

@IBDesignable
class MRRepetitionsView: UIView {
    
    private let label: UILabel = UILabel()
    private let image: UIImageView = UIImageView()
    
    private var lineWidth: CGFloat {
        return min(frame.width, frame.height) / 16
    }
    
    @IBInspectable
    var value: Int? {
        get { return _value }
        set(v) {
            _value = v.map { max(0, $0) }
            label.text = v.map { NumberFormatter().string(from: $0) } ?? nil
        }
    }
    
    var _value: Int? = nil
    
    var font: UIFont = UIFont.systemFont(ofSize: 17) {
        didSet {
            label.font = font
        }
    }
    
    private var fontSize: CGFloat {
        guard let text = label.text else { return label.font.pointSize }
        let font = label.font
        var fontSize = frame.height / 2.5
        var size = text.size(attributes: [NSFontAttributeName: (font?.withSize(fontSize))!])
        while (size.width > bounds.width - 8 * lineWidth) {
            fontSize -= 1
            size = text.size(attributes: [NSFontAttributeName: (font?.withSize(fontSize))!])
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
        image.image = UIImage(named: "repetitions")
        image.contentMode = .scaleAspectFit
        addSubview(image)
        addSubview(label)
    }
    
    override func draw(_ rect: CGRect) {
        label.frame = self.bounds
        label.textAlignment = .center
        label.textColor = MRColor.black
        label.font = label.font.withSize(fontSize)
        image.frame = self.bounds
    }
    
}
