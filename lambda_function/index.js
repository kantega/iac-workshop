const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const s3Client = new S3Client();
const dynamoClient = new DynamoDBClient();
const docClient = DynamoDBDocumentClient.from(dynamoClient);

exports.handler = async (event) => {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    // Get the DynamoDB table name from environment variable
    const tableName = process.env.DYNAMODB_TABLE_NAME;
    
    if (!tableName) {
        throw new Error('DYNAMODB_TABLE_NAME environment variable not set');
    }
    
    // Process each S3 event record
    for (const record of event.Records) {
        try {
            // Extract S3 bucket and key from the event
            const bucket = record.s3.bucket.name;
            const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
            
            console.log(`Processing file: ${key} from bucket: ${bucket}`);
            
            // Get the object from S3
            const getObjectCommand = new GetObjectCommand({
                Bucket: bucket,
                Key: key
            });
            
            const s3Response = await s3Client.send(getObjectCommand);
            
            // Read the stream content
            const streamToString = (stream) =>
                new Promise((resolve, reject) => {
                    const chunks = [];
                    stream.on('data', (chunk) => chunks.push(chunk));
                    stream.on('error', reject);
                    stream.on('end', () => resolve(Buffer.concat(chunks).toString('utf-8')));
                });
            
            const fileContent = await streamToString(s3Response.Body);
            console.log('File content retrieved, length:', fileContent.length);
            
            // Try to parse as JSON
            let jsonData;
            try {
                jsonData = JSON.parse(fileContent);
                console.log('Valid JSON detected');
            } catch (parseError) {
                console.log('File is not valid JSON, skipping:', parseError.message);
                continue; // Skip to next record
            }
            
            // Prepare the item for DynamoDB
            // Generate a unique ID and add metadata
            const item = {
                id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
                s3Bucket: bucket,
                s3Key: key,
                uploadTime: new Date().toISOString(),
                data: jsonData
            };
            
            // Write to DynamoDB
            const putCommand = new PutCommand({
                TableName: tableName,
                Item: item
            });
            
            await docClient.send(putCommand);
            console.log(`Successfully wrote to DynamoDB: ${item.id}`);
            
        } catch (error) {
            console.error('Error processing record:', error);
            throw error; // Throw to mark the invocation as failed
        }
    }
    
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Successfully processed S3 event',
            recordsProcessed: event.Records.length
        })
    };
};

