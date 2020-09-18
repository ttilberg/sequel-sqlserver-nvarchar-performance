Sequel.migration do
  change do
    create_table(:things) do
      primary_key :id
      String :name, null: false, index: true
    end

    puts <<~MSG
      Inserting 1,000,000 sample rows into [things].
      The values getting inserted are numbers that will get cast to whatever
      Sequel's default `String` migration column is for SQL Server.
      
      As of 2020, this is `varchar`.

      The goal of this table is to help understand the performance characteristics
      surrounding the fact that Sequel's default <String> migration uses <varchar>
      but its default querying datatype queries with unicode strings: `N'val'`.

      Internally, SQL Server has to do a little more work to do the conversion,
      and importantly cannot use the indexes.

      For details, see:
      https://www.sqlshack.com/query-performance-issues-on-varchar-data-type-using-an-n-prefix/

      This will take a moment...
    MSG

    data = 1_000_000.times.map{|i| {name: i}}
    DB[:things].multi_insert(data, slice: 1000)

    puts "Done."
  end
end
