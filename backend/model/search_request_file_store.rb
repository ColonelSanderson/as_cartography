class SearchRequestFileStore

  def store_file(upload_file)
    ByteStorage.get.store(upload_file.tempfile)
  end

  def get_file(key, &block)
    ByteStorage.get.get_stream(key, &block)
  end

end
