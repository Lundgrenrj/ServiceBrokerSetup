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
    private static readonly string s3Key = "exports/full_export.csv"; // S3 file path

    static async Task Main()
    {
        Console.WriteLine("Starting stream export...");
        await StreamExportToS3();
        Console.WriteLine("Export completed.");
    }

    static async Task StreamExportToS3()
    {
        using var connection = new SqlConnection(connectionString);
        using var command = new SqlCommand("SELECT * FROM YourTable", connection);
        await connection.OpenAsync();
        using var reader = await command.ExecuteReaderAsync();

        using var memoryStream = new MemoryStream();
        using var writer = new StreamWriter(memoryStream, Encoding.UTF8);

        // Write header
        writer.WriteLine(GetCsvHeader(reader));

        while (await reader.ReadAsync())
        {
            writer.WriteLine(GetCsvRow(reader));

            // Periodically flush and upload
            if (memoryStream.Length > 5 * 1024 * 1024) // Every 5MB
            {
                await UploadToS3(memoryStream);
            }
        }

        // Final upload of remaining data
        if (memoryStream.Length > 0)
        {
            await UploadToS3(memoryStream);
        }
    }

    static async Task UploadToS3(MemoryStream memoryStream)
    {
        using var s3Client = new AmazonS3Client();

        memoryStream.Position = 0; // Reset stream position
        var request = new PutObjectRequest
        {
            BucketName = bucketName,
            Key = s3Key,
            InputStream = memoryStream,
            ContentType = "text/csv"
        };

        await s3Client.PutObjectAsync(request);
        Console.WriteLine($"Uploaded {memoryStream.Length} bytes to S3.");

        memoryStream.SetLength(0); // Clear stream for next batch
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
        {
            string value = reader[i]?.ToString() ?? "";
            if (value.Contains(",") || value.Contains("\"") || value.Contains("\n"))
                value = "\"" + value.Replace("\"", "\"\"") + "\"";
            values[i] = value;
        }

        return string.Join(",", values);
    }
}
