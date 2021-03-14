//
//  ViewController.swift
//  SmartCamera
//
//  Created by Dayo Banjo on 3/13/21.
//

import UIKit
import AVKit
import AVFoundation
import Vision


class ViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var faceLayers: [CAShapeLayer] = []
    var centerCell : FilterCollectionViewCell!
    
    private var currentIndex = 0
    private var filters = ["dog-nose", "dog-full","dog-tongue", "dog-cat1", "dog-cat2"]
    let image = UIImage(named: "dog full")
    let uiImageView = UIImageView(image: UIImage(named: "dog-tongue"))
    let faceLayer = CAShapeLayer()
    
    fileprivate let realityCollectionView : UICollectionView = {
        let layout  = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        let collectionView = UICollectionView(frame: CGRect(x: 6, y: UIScreen.main.bounds.height - 120, width: UIScreen.main.bounds.width - 12, height: 120), collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: FilterCollectionViewCell.identifier)
        return collectionView
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        faceLayer.contents = UIImage(named: "dog-white")?.cgImage
        uiImageView.isHidden = true
        setupCamera()
        setupCollectionViews() 
        captureSession.startRunning()
        view.addSubview(uiImageView)
    }
    
    private func setupCollectionViews(){
        
        view.addSubview(self.realityCollectionView)
        self.realityCollectionView.isUserInteractionEnabled = true
        
        realityCollectionView.delegate = self
        realityCollectionView.dataSource = self
        realityCollectionView.isScrollEnabled = true
        self.view.bringSubviewToFront(self.realityCollectionView)
        
    }
    
    private func setupCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                    
                    setupPreview()
                }
            }
        }
    }
    
    private func setupPreview() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
        
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }

    override var prefersStatusBarHidden: Bool{
        return true
    }


}


extension ViewController :  UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCollectionViewCell.identifier, for: indexPath) as! FilterCollectionViewCell
        cell.configureFilter(filters[indexPath.row])
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height:  80)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = realityCollectionView.cellForItem(at: indexPath) as? FilterCollectionViewCell
        cell?.subView.layer.borderColor = UIColor.blue.cgColor
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentIndex = indexPath.row
        uiImageView.image = UIImage(named: filters[indexPath.row])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView is UICollectionView else {return}
        let centerPoint = CGPoint(x: self.realityCollectionView.frame.size.width/2  + scrollView.contentOffset.x, y: self.realityCollectionView.frame.size.height/2  + scrollView.contentOffset.y)
        
        if let indexPath = self.realityCollectionView.indexPathForItem(at: centerPoint){
            self.centerCell = (self.realityCollectionView.cellForItem(at: indexPath) as! FilterCollectionViewCell)
            self.centerCell.transformImageToLarge()
        }
        
        if let cell = self.centerCell {
            let offset = centerPoint.x  - cell.center.x
            print("The offset \(offset)")
            if offset < -30 || offset > 30{
                cell.resizeTransformToStandard()
                self.centerCell = nil
            }
        }
    }
    


    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {[weak self] in 
                self?.faceLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
                
                if let observations = request.results as? [VNFaceObservation] {
                    self?.uiImageView.isHidden = false
                    self?.handleFaceDetectionObservations(observations: observations)
                } else{
                    self?.uiImageView.isHidden = true
                }
            }
        })
        
        // use front camera because it is like left mirror 
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])
        
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func handleFaceDetectionObservations(observations: [VNFaceObservation]) {
        if observations.count == 0{
            uiImageView.isHidden = true
        } else {
            uiImageView.isHidden = false
        }        
        
        let margin = currentIndex > 2 ? 120 : 30
        
        for observation in observations {
                    let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
                    let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
                    
                    faceLayer.path = faceRectanglePath 
            uiImageView.frame = CGRect(x: faceRectanglePath.boundingBox.origin.x - 40, y: faceRectanglePath.boundingBox.origin.y - CGFloat(margin),
                                               width: faceRectanglePath.boundingBox.width + 70, height: faceRectanglePath.boundingBox.height + 70)
        }
        
   }
  
}
