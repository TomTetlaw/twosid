
CreateAndMapBuffer :: (Device: *SDL_GPUDevice, Name: string, Size: int, Usage: SDL_GPUBufferUsageFlags) -> *SDL_GPUBuffer, *SDL_GPUTransferBuffer, *u8 {
    CreateInfo: SDL_GPUBufferCreateInfo;
    CreateInfo.usage = Usage;
    CreateInfo.size = xx Size;
    Buffer := SDL_CreateGPUBuffer(Device, *CreateInfo);
    SDL_SetGPUBufferName(Device, Buffer, Name.data);
    
    TransferCreateInfo: SDL_GPUTransferBufferCreateInfo;
    TransferCreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    TransferCreateInfo.size = xx Size;
    TransferBuffer := SDL_CreateGPUTransferBuffer(Device, *TransferCreateInfo);
    
    Memory := SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
    return Buffer, TransferBuffer, Memory;
}

CommitMappedBuffer :: (Device: *SDL_GPUDevice, Buffer: *SDL_GPUBuffer, TransferBuffer: *SDL_GPUTransferBuffer, Size: int) {
    SDL_UnmapGPUTransferBuffer(Device, TransferBuffer);
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(Device);
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.buffer = Buffer;
    Region.offset = 0;
    Region.size = xx Size;
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
    
    SDL_EndGPUCopyPass(CopyPass);
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    SDL_ReleaseGPUTransferBuffer(Device, TransferBuffer);
}

CreateVertexBuffer :: (Device: *SDL_GPUDevice, Name: string, Stride: int, Elements: int) -> *SDL_GPUBuffer {
    VertexCreateInfo: SDL_GPUBufferCreateInfo;
    VertexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
    VertexCreateInfo.size = xx (Stride * Elements);
    Buffer := SDL_CreateGPUBuffer(Device, *VertexCreateInfo);
    SDL_SetGPUBufferName(Device, Buffer, Name.data);
    return Buffer;
}

CreateIndexBuffer :: (Device: *SDL_GPUDevice, Name: string, Elements: int) -> *SDL_GPUBuffer {
    IndexCreateInfo: SDL_GPUBufferCreateInfo;
    IndexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_INDEX;
    IndexCreateInfo.size = xx (Elements * size_of(u32));
    Buffer := SDL_CreateGPUBuffer(Device, *IndexCreateInfo);
    SDL_SetGPUBufferName(Device, Buffer, Name.data);
    return Buffer;
}

CreateInstanceBuffer :: (Device: *SDL_GPUDevice, Name: string, Data: [] $T) -> *SDL_GPUBuffer {
    InstanceBuffer, TransferBuffer, Memory := CreateAndMapBuffer(Device, Name, size_of(T) * MAX_INSTANCES, SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ);
    memcpy(Memory, Data.data, size_of(T) * Data.count);
    CommitMappedBuffer(Device, InstanceBuffer, TransferBuffer, size_of(T) * Data.count);
    return InstanceBuffer;
}