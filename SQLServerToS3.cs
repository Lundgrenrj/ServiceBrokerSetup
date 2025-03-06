using System;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Amazon.S3;
using Amazon.S3.Model;

class Program
{
    private static readonly string connectionString = "Your SQL Server Connection String";
    private static readonly string bucketName = "your-s3-bucket";
    private static readonly string s3Folder = "exports/";

    static async Task Main()
    {
        Console.WriteLine("Starting export...");
        await ExportToS3InBatches();
        Console.WriteLine("Export completed.");
    }

    static async Task ExportToS3InBatches()
    {
        using var connection = new SqlConnection(connectionString);
        using var command = new SqlCommand("SELECT * FROM YourTable", connection);
        await connection.OpenAsync();

        using var reader = await command.ExecuteReaderAsync();

        int batchSize = 100000;
        int batchNumber = 1;
        int recordCount = 0;

        StringBuilder csvBuilder = new StringBuilder();
        csvBuilder.AppendLine(GetCsvHeader(reader)); // Add CSV header once

        while (await reader.ReadAsync())
        {
            csvBuilder.AppendLine(GetCsvRow(reader));
            recordCount++;

            if (recordCount % batchSize == 0) // Upload every 100,000 rows
            {
                await UploadBatchToS3(csvBuilder, batchNumber);
                batchNumber++;
                csvBuilder.Clear(); // Clear memory for next batch
            }
        }

        // Upload the last batch if it has remaining records
        if (csvBuilder.Length > 0)
        {
            await UploadBatchToS3(csvBuilder, batchNumber);
        }
    }

    static string GetCsvHeader(SqlDataReader reader)
    {
        int fieldCount = reader.FieldCount;
        string[] columns = new string[fieldCount];

        for (int i = 0; i < fieldCount; i++)
            columns[i] = reader.GetName(i);

        return string.Join(",", columns);
    }

    static string GetCsvRow(SqlDataReader reader)
    {
        int fieldCount = reader.FieldCount;
        string[] values = new string[fieldCount];

        for (int i = 0; i < fieldCount; i++)
            values[i] = reader[i]?.ToString().Replace(",", " "); // Handle commas safely

        return string.Join(",", values);
    }

    static async Task UploadBatchToS3(StringBuilder csvData, int batchNumber)
    {
        using var s3Client = new AmazonS3Client();
        using var memoryStream = new MemoryStream(Encoding.UTF8.GetBytes(csvData.ToString()));

        var request = new PutObjectRequest
        {
            BucketName = bucketName,
            Key = $"{s3Folder}export_batch_{batchNumber}.csv",
            InputStream = memoryStream,
            ContentType = "text/csv"
        };

        await s3Client.PutObjectAsync(request);
        Console.WriteLine($"Batch {batchNumber} uploaded to S3.");
    }
}
