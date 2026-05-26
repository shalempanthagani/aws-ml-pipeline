package com.example.fileupload.controller;

import com.example.fileupload.service.S3Service;
import com.example.fileupload.service.S3Service.PresignedUrlResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/upload")
public class FileUploadController {

    private final S3Service s3Service;

    public FileUploadController(S3Service s3Service) {
        this.s3Service = s3Service;
    }

    @PostMapping("/presigned-url")
    public ResponseEntity<PresignedUrlResponse> getPresignedUrl(
            @RequestBody PresignedUrlRequest request
    ) {
        PresignedUrlResponse response = s3Service.generatePresignedPutUrl(
                request.filename(),
                request.contentType()
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("OK");
    }

    public record PresignedUrlRequest(
            String filename,
            String contentType
    ) {}
}