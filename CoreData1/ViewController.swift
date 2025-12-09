//
//  ViewController.swift
//  CoreData1
//
//  Created by Koushik Reddy Kambham on 12/8/25.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Properties
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter a new to-do..."
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let sortFilterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Incomplete", "Sort by Name"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private var todos: [Todo] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchTodos()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "To-Do List"

        // Add Subviews
        view.addSubview(sortFilterControl)
        view.addSubview(textField)
        view.addSubview(addButton)
        view.addSubview(tableView)

        // Set Delegates
        tableView.dataSource = self
        tableView.delegate = self

        // Layout
        NSLayoutConstraint.activate([
            sortFilterControl.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            sortFilterControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sortFilterControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            addButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            addButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 10),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: sortFilterControl.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add Target
        addButton.addTarget(self, action: #selector(addTodo), for: .touchUpInside)
        sortFilterControl.addTarget(self, action: #selector(sortFilterChanged(_:)), for: .valueChanged)
    }

    // MARK: - Core Data Methods
    private func fetchTodos() {
        let request: NSFetchRequest<Todo> = Todo.fetchRequest()

        // Sorting
        let sortDescriptor: NSSortDescriptor
        if sortFilterControl.selectedSegmentIndex == 2 {
            sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        } else {
            sortDescriptor = NSSortDescriptor(key: "completed", ascending: true)
        }
        request.sortDescriptors = [sortDescriptor]

        // Filtering
        switch sortFilterControl.selectedSegmentIndex {
        case 1: // Incomplete
            request.predicate = NSPredicate(format: "completed == %@", NSNumber(value: false))
        default: // All or Sort by Name
            request.predicate = nil
        }

        do {
            todos = try context.fetch(request)
            tableView.reloadData()
        } catch {
            print("Error fetching todos: \(error)")
        }
    }

    private func saveTodos() {
        do {
            try context.save()
            fetchTodos()
        } catch {
            print("Error saving todos: \(error)")
        }
    }

    // MARK: - Actions
    @objc private func addTodo() {
        guard let text = textField.text, !text.isEmpty else { return }
        let newTodo = Todo(context: context)
        newTodo.title = text
        newTodo.completed = false
        saveTodos()
        textField.text = ""
    }

    @objc private func sortFilterChanged(_ sender: UISegmentedControl) {
        fetchTodos()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        let todo = todos[indexPath.row]
        cell.textLabel?.text = todo.title
        cell.textLabel?.textColor = todo.completed ? .green : .black
        cell.accessoryType = todo.completed ? .checkmark : .none
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let todo = todos[indexPath.row]
        todo.completed.toggle()
        saveTodos()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            let todo = self.todos[indexPath.row]
            self.context.delete(todo)
            self.saveTodos()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
