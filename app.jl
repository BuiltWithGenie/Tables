using GenieFramework
@genietools
using StippleTables, StipplePivotTable, DataFrames, SQLite

df = DataFrame(
    ID = 1:20,
    Department = repeat(["Sales", "Marketing", "IT", "HR"], 5),
    Employee = ["Emp" * string(i) for i in 1:20],
    Salary = rand(50000:5000:100000, 20),
    Sales = rand(50000:5000:100000, 20),
    HireDate = Date(2020,1,1) .+ Day.(rand(1:1000, 20)),
    Performance = rand(["Excellent", "Good", "Average", "Poor"], 20)
)
db = SQLite.DB("employees.sqlite")


@app begin
    @out title = "Employee data"
    @out table = DataTable(df)
    @out x::Vector{Any} = df[:,"Employee"]
    @out y = df[:,"Sales"]
    @in x_var = "Salary"
    @out x_options = names(df)

    @onchange x_var begin
        x = df[:, x_var]
    end

    # data grouping
    @in group_by = "Department"
    @out group_by_options = ["Department", "HireDate", "Performance"]
    @in groupkeys::Vector{Any} = unique(df[!, :Department])
    @in selectedkey = "Sales"
    @private gdf = groupby(df, "Department")

    @onchange group_by begin
        if group_by == ""
            groupkeys = []
            table = DataTable(df)
        else
            groupkeys = unique(df[:,group_by])
            gdf = groupby(df, group_by)  
            selectedkey = first(groupkeys)
        end
    end

    @onchange selectedkey begin
      table = gdf[(selectedkey,)] |> DataFrame |> DataTable
    end


    # database integration
    @out r_max =  maximum(df[:,"Sales"])    
    @out r_min = minimum(df[:,"Sales"])
    @in r = RangeData(0:100000)
    @out table_range = DataTable(df)

    @onchange r begin
        query = """
                SELECT * FROM employees 
                WHERE Salary BETWEEN ? AND ?
                ORDER BY Sales;
                """
        table_range = DBInterface.execute(db, query, (r.range.start, r.range.stop)) |> DataFrame |> DataTable
    end

    # pivot table
    @out pivot_rows = ["Employee"]
    @out pivot_cols = ["Department", "Performance"]
    @out pivot_vals = ["Sales"]
    @out array_table = vcat([names(df)], Vector.(collect(eachrow(df))))

    # data aggregation
    @in aggregate_by::Vector{String} = []
    @out aggregate_by_options = ["Employee", "Department", "Performance"]
    @in aggregate_target = ""
    @out aggregate_target_options = ["Salary", "Sales"]   

    @onchange aggregate_by begin
        if aggregate_by == []
            table = DataTable(df)
            aggregate_target = ""
        else
            aggregate_target = first(aggregate_target_options)
        end
    end

    @onchange aggregate_target begin
        if aggregate_target != ""
            gdf = groupby(df, aggregate_by)
            table = combine(gdf, aggregate_target => sum => aggregate_target) |> DataTable
          end
    end
end


@page("/", "app.jl.html")
