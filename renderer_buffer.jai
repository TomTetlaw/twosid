
CreateVertexBuffer :: (Name: string, Stride: int, Elements: int) -> *SDL_GPUBuffer {
    VertexCreateInfo: SDL_GPUBufferCreateInfo;
    VertexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
    VertexCreateInfo.size = xx (Stride * Elements);
    Buffer := SDL_CreateGPUBuffer(GDevice, *VertexCreateInfo);
    SDL_SetGPUBufferName(GDevice, Buffer, TCS(Name));
    return Buffer;
}

CreateIndexBuffer :: (Name: string, Elements: int) -> *SDL_GPUBuffer {
    IndexCreateInfo: SDL_GPUBufferCreateInfo;
    IndexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_INDEX;
    IndexCreateInfo.size = xx (Elements * size_of(u32));
    Buffer := SDL_CreateGPUBuffer(GDevice, *IndexCreateInfo);
    SDL_SetGPUBufferName(GDevice, Buffer, TCS(Name));
    return Buffer;
}

CreateBuffer :: (Name: string, Size: int, Usage: SDL_GPUBufferUsageFlags) -> *SDL_GPUBuffer {
    CreateInfo: SDL_GPUBufferCreateInfo;
    CreateInfo.usage = Usage;
    CreateInfo.size = xx Size;
    Buffer := SDL_CreateGPUBuffer(GDevice, *CreateInfo);
    SDL_SetGPUBufferName(GDevice, Buffer, TCS(Name));
    return Buffer;
}

CreateTransferBuffer :: (Size: int) -> *SDL_GPUTransferBuffer {
    TransferCreateInfo: SDL_GPUTransferBufferCreateInfo;
    TransferCreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    TransferCreateInfo.size = xx Size;
    return SDL_CreateGPUTransferBuffer(GDevice, *TransferCreateInfo);
}

CreateVertexBuffer :: (Name: string, Elements: [] $T) -> *SDL_GPUBuffer {
    Buffer := CreateVertexBuffer(Name, size_of(T), Elements.count);
    
    TransferBuffer := CreateTransferBuffer(Elements.count * size_of(T));
    
    TransferMemory := SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
    Copy(TransferMemory, Elements.data, size_of(T) * Elements.count);
    SDL_UnmapGPUTransferBuffer(GDevice, TransferBuffer);
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.offset = 0;
    Region.buffer = Buffer;
    Region.size = xx (size_of(T) * Elements.count);
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
    
    SDL_EndGPUCopyPass(CopyPass);
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    SDL_ReleaseGPUTransferBuffer(GDevice, TransferBuffer);
    
    return Buffer;
}

CreateIndexBuffer :: (Name: string, Elements: [] u32) -> *SDL_GPUBuffer {
    Buffer := CreateIndexBuffer(Name, Elements.count);
    
    TransferBuffer := CreateTransferBuffer(Elements.count * size_of(u32));
    
    TransferMemory := SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
    Copy(TransferMemory, Elements.data, size_of(u32) * Elements.count);
    SDL_UnmapGPUTransferBuffer(GDevice, TransferBuffer);
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.offset = 0;
    Region.buffer = Buffer;
    Region.size = xx (size_of(u32) * Elements.count);
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
    
    SDL_EndGPUCopyPass(CopyPass);
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    SDL_ReleaseGPUTransferBuffer(GDevice, TransferBuffer);
    
    return Buffer;
}

structured_buffer :: struct {
    Buffer: *SDL_GPUBuffer;
    TransferBuffer: *SDL_GPUTransferBuffer;
    Used: int;
    Capacity: int;
    Mapping: *void;
}

CreateStructuredBuffer :: (Name: string, Capacity: int) -> *structured_buffer {
    StructuredBuffer := ArenaAlloc(*RendererArena, structured_buffer);
    StructuredBuffer.Buffer = CreateBuffer(Name, Capacity, SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ);
    StructuredBuffer.TransferBuffer = CreateTransferBuffer(Capacity);
    StructuredBuffer.Capacity = Capacity;
    return StructuredBuffer;
}

MapStructuredBuffer :: (StructuredBuffer: *structured_buffer) {
    StructuredBuffer.Used = 0;
    StructuredBuffer.Mapping = SDL_MapGPUTransferBuffer(GDevice, StructuredBuffer.TransferBuffer, false);
}

UnmapStructuredBuffer :: (StructuredBuffer: *structured_buffer) {
    SDL_UnmapGPUTransferBuffer(GDevice, StructuredBuffer.TransferBuffer);
    StructuredBuffer.Mapping = null;
}

WriteStructuredBuffer :: (StructuredBuffer: *structured_buffer, Data: [] $T) {
    Size := Data.count * size_of(T);
    Count := Min(Size, StructuredBuffer.Capacity - StructuredBuffer.Used);
    
    Copy(StructuredBuffer.Mapping + StructuredBuffer.Used, Data.data, Size);
    StructuredBuffer.Used += Count;
}

WriteStructuredBuffer :: (StructuredBuffer: *structured_buffer, Data: *void, Size: int) {
    Count := Min(Size, StructuredBuffer.Capacity - StructuredBuffer.Used);
    
    Copy(StructuredBuffer.Mapping + StructuredBuffer.Used, Data, Size);
    StructuredBuffer.Used += Count;
}

CommitStructuredBuffer :: (StructuredBuffer: *structured_buffer, CopyPass: *SDL_GPUCopyPass) {
    if StructuredBuffer.Used == 0 return;
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = StructuredBuffer.TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.buffer = StructuredBuffer.Buffer;
    Region.offset = 0;
    Region.size = xx StructuredBuffer.Used;
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
}