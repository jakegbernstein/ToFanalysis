%Test script
[files, frames, movies] = parseCSV();
frame = frames(2);
[frame, files] = processFrame(frame, files);
distancemeasured = 53*2.54/100;
offset = calibratePhaseOffset(frame,distancemeasured);
frame.distances = frame.distances + offset;
[xyz, ptcloud] = sensor2xyz(frame);