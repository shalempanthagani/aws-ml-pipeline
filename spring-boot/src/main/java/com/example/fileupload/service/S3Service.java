package com.example.fileupload.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.time.Duration;
import java.util.UUID;

@Service
public class S3Service {

    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket:ml-pipeline-dev-bucket}")
    private String bucketName;

    @Value("${aws.s3.presigned-url.expiry-minutes:15}")
    private int expiryMinutes;

    public S3Service(S3Presigner s3Presigner) {
        this.s3Presigner = s3Presigner;
    }

    public PresignedUrlResponse generatePresignedPutUrl(String filename, String contentType) {
        String key = "raw/" + UUID.randomUUID() + "_" + filename;

        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(contentType)
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(expiryMinutes))
                .putObjectRequest(putObjectRequest)
                .build();

        PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);

        return new PresignedUrlResponse(
                presignedRequest.url().toString(),
                key,
                bucketName,
                expiryMinutes
        );
    }

    public record PresignedUrlResponse(
            String uploadUrl,
            String s3Key,
            String bucket,
            int expiresInMinutes
    ) {}
}