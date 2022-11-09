import Combine
//import NetworkImage
import SwiftUI
import Kingfisher

/// A type that encapsulates the image loading behavior of a ``Markdown`` view for a given URL scheme.
///
/// To configure an image handler for a `Markdown` view, use the ``Markdown/setImageHandler(_:forURLScheme:)``
/// modifier. The following example configures an asset image handler for the `asset://` URL scheme.
///
/// ```swift
/// Markdown(
///   #"""
///   ![](asset:///Puppy)
///
///   ― Photo by André Spieker
///   """#
/// )
/// .setImageHandler(.assetImage(), forURLScheme: "asset")
/// ```
///
public struct MarkdownImageHandler {
  var imageAttachment: (URL) -> AnyPublisher<NSTextAttachment, Never>

  public init(imageAttachment: @escaping (URL) -> AnyPublisher<NSTextAttachment, Never>) {
    self.imageAttachment = imageAttachment
  }
}

extension MarkdownImageHandler {
  /// A `MarkdownImageHandler` instance that loads images from the network.
  ///
  /// `Markdown` views use this image handler for the `http://` and `https://`
  /// schemes by default.
  public static let networkImage = MarkdownImageHandler { url in
	  let subject = PassthroughSubject<NSTextAttachment, Never>()

	  KingfisherManager.shared.retrieveImage(with: url, completionHandler: { result in
		  switch result {
		  case .success(let value):
			  let attachment = ResizableImageAttachment()
			  attachment.image = value.image
			  subject.send(attachment)
		  case .failure(let error):
			  subject.send(NSTextAttachment())
		  }
	  })
	  
	  return subject.eraseToAnyPublisher()
	  
//    NetworkImageLoader.shared.image(for: url)
//      .map { image in
//        let attachment = ResizableImageAttachment()
//        attachment.image = image
//        return attachment
//      }
//      .replaceError(with: NSTextAttachment())
//      .eraseToAnyPublisher()
  }

  /// A `MarkdownImageHandler` instance that loads images from resource files or asset catalogs.
  /// - Parameters:
  ///   - name: A closure that extracts the asset name from a given URL. If not specified, the image handler
  ///           uses the last path component of the URL as the name of the asset.
  ///   - bundle: The bundle to search for the image file or asset catalog. Specify `nil` to search the
  ///             app's main bundle.
  public static func assetImage(
    name: @escaping (URL) -> String = \.lastPathComponent,
    in bundle: Bundle? = nil
  ) -> MarkdownImageHandler {
    MarkdownImageHandler { url in
      #if os(macOS)
		let image: NSImage?
        if let bundle = bundle, bundle != .main {
          image = bundle.image(forResource: name(url))
        } else {
          image = NSImage(named: name(url))
        }
      #elseif os(iOS) || os(tvOS)
		let image : UIImage?
        image = UIImage(named: name(url), in: bundle, compatibleWith: nil)
      #endif
      let attachment = image.map { image -> NSTextAttachment in
        let result = ResizableImageAttachment()
        result.image = image
        return result
      }
      return Just(attachment ?? NSTextAttachment()).eraseToAnyPublisher()
    }
  }
}
