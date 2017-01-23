def dummy_logger
  logger = double()
  allow(logger).to receive(:debug).and_return(true)
  allow(logger).to receive(:warn).and_return(true)
  return logger
end
