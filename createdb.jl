using DataFrames
using SQLite
using Dates

# Create the DataFrame
df = DataFrame(
    ID = 1:20,
    Department = repeat(["Sales", "Marketing", "IT", "HR"], 5),
    Employee = ["Emp" * string(i) for i in 1:20],
    Salary = rand(50000:5000:100000, 20),
    Sales = rand(50000:5000:100000, 20),
    HireDate = Date(2020,1,1) .+ Day.(rand(1:1000, 20)),
    Performance = rand(["Excellent", "Good", "Average", "Poor"], 20)
)

# Connect to a new SQLite database
db = SQLite.DB("employees.sqlite")

# Create the table
SQLite.execute(db, """
    CREATE TABLE IF NOT EXISTS employees (
        ID INTEGER PRIMARY KEY,
        Department TEXT,
        Employee TEXT,
        Salary INTEGER,
        Sales INTEGER,
        HireDate DATE,
        Performance TEXT
    )
""")

# Prepare the INSERT statement
stmt = SQLite.Stmt(db, """
    INSERT INTO employees (ID, Department, Employee, Salary, Sales, HireDate, Performance)
    VALUES (?, ?, ?, ?, ?, ?, ?)
""")

# Insert data row by row
SQLite.transaction(db) do
    for row in eachrow(df)
        SQLite.execute(stmt, (row.ID, row.Department, row.Employee, row.Salary, row.Sales, row.HireDate, row.Performance))
    end
end

# Close the database connection
SQLite.close(db)
