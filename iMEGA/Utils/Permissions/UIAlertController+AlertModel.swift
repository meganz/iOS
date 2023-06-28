extension UIAlertController {
    convenience init(model: AlertModel) {
        self.init(title: model.title, message: model.message, preferredStyle: .alert)
        model.actions.forEach { action in
            addAction(.init(title: action.title, style: action.style, handler: { _ in action.handler() }))
        }
    }
}
