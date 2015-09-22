# FakeAmbientSensorSwift
As far as Apple does not provide public API to access light ambient sensor, I made this class to help getting luminascence from front camera.

Code is using AVFoundation to get Camera session and access picture pixels.
This pixels are then transformed using:

let luminance:Double = Double(((r * 0.299) + (g * 0.587) + (b * 0.114))*a)

To get value for current pixel -> then mean value is calculated and transformed into alpha value of current view:

self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(1.0 - finalValue))
  
