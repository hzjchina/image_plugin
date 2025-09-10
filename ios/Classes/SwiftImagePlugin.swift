import Flutter
import UIKit
import PhotosUI

public class SwiftImagePlugin: NSObject, FlutterPlugin, PHPickerViewControllerDelegate {
    private var resultCallBack: FlutterResult!
    private var registrar: FlutterPluginRegistrar?
    
    @available(iOS 14.0, *)
    private func pickImages(maxImages: Int) {
        //        guard let viewController = registrar?.viewController() else {
        //        guard let viewController = getCurrentViewController() else {
        guard let viewController = topViewController() else {
            resultCallBack?(FlutterError(code: "NO_VIEW_CONTROLLER", message: "NO_VIEW_CONTROLLER", details: nil))
            resultCallBack = nil
            return
        }
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = maxImages
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
    
    @available(iOS 14.0, *)
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let pendingResult = resultCallBack else { return }
        self.resultCallBack = nil
        
        let group = DispatchGroup()
        var imagePaths: [String] = []
        
        for result in results {
            group.enter()
            let itemProvider = result.itemProvider
            
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    defer { group.leave() }
                    guard let image = object as? UIImage, error == nil else { return }
                    if let path = self?.saveImageToTempDirectory(image: image) {
                        imagePaths.append(path)
                    }
                }
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            pendingResult(imagePaths)
        }
    }
    
    private func saveImageToTempDirectory(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        if #available(iOS 10.0, *) {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            do {
                try data.write(to: url)
                return url.path
            } catch {
                //print("保存失败: $error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    // 获取当前顶层视图控制器
    private func getCurrentViewController() -> UIViewController? {
        // 从应用的主窗口获取根视图控制器
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let rootViewController = window.rootViewController {
            return findTopViewController(from: rootViewController)
        }
        return nil
    }
    
    // 递归查找最顶层的视图控制器
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        // 如果有presented视图控制器，则继续查找
        if let presentedViewController = viewController.presentedViewController {
            return findTopViewController(from: presentedViewController)
        }
        
        // 处理导航控制器
        if let navigationController = viewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            return findTopViewController(from: topViewController)
        }
        
        // 处理标签栏控制器
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return findTopViewController(from: selectedViewController)
        }
        
        // 如果是其他类型的视图控制器，直接返回
        return viewController
    }
    
    private func topViewController() -> UIViewController? {
        guard let root = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        return findTop(from: root)
    }
    
    private func findTop(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController { return findTop(from: presented) }
        if let nav = vc as? UINavigationController, let top = nav.topViewController {
            return findTop(from: top)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return findTop(from: selected)
        }
        return vc
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "image_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftImagePlugin()
        instance.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.resultCallBack = result;
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            break
        case "pickImages":
            guard let args = call.arguments as? [String: Any],
                  let maxImages = args["maxImages"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "INVALID_ARGUMENTS", details: nil))
                return
            }
            if #available(iOS 14.0, *) {
                self.resultCallBack = result
                pickImages(maxImages: maxImages)
            } else {
                result(FlutterError(code: "UNSUPPORTED_OS", message: "UNSUPPORTED_OS_14+", details: nil))
            }
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
