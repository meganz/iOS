extension CustomModalAlertViewController {
    
    func configure(with model: CustomModalModel) {
        image = model.image
        viewTitle = model.viewTitle
        detail = model.details
        firstButtonTitle = model.firstButtonTitle
        dismissButtonTitle = model.dismissButtonTitle
        
        firstCompletion = {[weak self] in
            let dismisser = Dismisser {
                self?.dismiss(animated: true, completion: {})
            }
            model.firstCompletion(dismisser)
        }
    }
}
