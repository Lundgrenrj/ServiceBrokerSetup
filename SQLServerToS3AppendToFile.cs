using System;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Amazon.S3;
using Amazon.S3.Model;
using System.Collections.Generic;

class Program
{
    private static readonly string connectionString = "Your SQL Server Connection String";
    private static readonly string bucketName = "your-s3-bucket";
    private static readonly string s3Key = "exports/full_export.csv"; // S3 file path

    static async Task Main()
    {
        Console.WriteLine("Starting multi-part upload...");
        await StreamExportToS3();
        Console.WriteLine("Upload completed.");
    }

    static async Task StreamExportToS3()
    {
        using var connection = new SqlConnection(connectionString);
        using var command = new SqlCommand("SELECT * FROM YourTable", connection);
        await connection.OpenAsync();
        using var reader = await command.ExecuteReaderAsync();

        using var s3Client = new AmazonS3Client();

        // Start multi-part upload
        var initiateRequest = new InitiateMultipartUploadRequest
        {
            BucketName = bucketName,
            Key = s3Key,
            ContentType = "text/csv"
        };
        var initiateResponse = await s3Client.InitiateMultipartUploadAsync(initiateRequest);
        string uploadId = initiateResponse.UploadId;

        var partETags = new List<PartETag>();
        int partNumber = 1;

        using var memoryStream = new MemoryStream();
        using var writer = new StreamWriter(memoryStream, Encoding.UTF8);

        // Write header
        writer.WriteLine(GetCsvHeader(reader));

        while (await reader.ReadAsync())
        {
            writer.WriteLine(GetCsvRow(reader));

            // Every 5MB, upload a part
            if (memoryStream.Length > 5 * 1024 * 1024) // 5MB threshold
            {
                await UploadPartToS3(s3Client, uploadId, partNumber++, memoryStream, partETags);
            }
        }

        // Upload final chunk if there's remaining data
        if (memoryStream.Length > 0)
        {
            await UploadPartToS3(s3Client, uploadId, partNumber++, memoryStream, partETags);
        }

        // Complete multi-part upload
        var completeRequest = new CompleteMultipartUploadRequest
        {
            BucketName = bucketName,
            Key = s3Key,
            UploadId = uploadId,
            PartETags = partETags
        };
        await s3Client.CompleteMultipartUploadAsync(completeRequest);
        Console.WriteLine("Multi-part upload completed successfully.");
    }

    static async Task UploadPartToS3(AmazonS3Client s3Client, string uploadId, int partNumber, MemoryStream memoryStream, List<PartETag> partETags)
    {
        memoryStream.Position = 0; // Reset stream position

        var uploadRequest = new UploadPartRequest
        {
            BucketName = bucketName,
            Key = s3Key,
            UploadId = uploadId,
            PartNumber = partNumber,
            InputStream = memoryStream,
            PartSize = memoryStream.Length
        };

        var uploadResponse = await s3Client.UploadPartAsync(uploadRequest);
        partETags.Add(new PartETag(partNumber, uploadResponse.ETag));

        Console.WriteLine($"Uploaded part {partNumber}, size: {memoryStream.Length} bytes");

        memoryStream.SetLength(0); // Clear memory stream for next batch
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
