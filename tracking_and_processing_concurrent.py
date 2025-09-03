import cv2
import numpy as np
from ultralytics import YOLO
import os
from datetime import datetime
import json
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
from pathlib import Path
import glob

# Thread-safe counter for person numbering across all videos
class ThreadSafeCounter:
    def __init__(self):
        self._value = 0
        self._lock = threading.Lock()
    
    def increment(self):
        with self._lock:
            self._value += 1
            return self._value

# Global counter for unique person numbering
global_person_counter = ThreadSafeCounter()

def load_models():
    """Load YOLO models - called once per thread"""
    person_model = YOLO("yolov8s.pt")
    tshirt_model = YOLO("tshirt_detection_model.pt")
    return person_model, tshirt_model

def process_single_video(video_path, output_base_dir="detected_people"):
    """Process a single video file"""
    video_name = Path(video_path).stem
    video_output_dir = os.path.join(output_base_dir, video_name)
    os.makedirs(video_output_dir, exist_ok=True)
    
    print(f"[{video_name}] Starting processing...")
    
    # Load models for this thread
    print(f"[{video_name}] Loading models...")
    model_start_time = time.time()
    person_model, tshirt_model = load_models()
    model_load_time = time.time() - model_start_time
    print(f"[{video_name}] Models loaded in {model_load_time:.2f} seconds")
    
    # Load video
    videoCap = cv2.VideoCapture(video_path)
    if not videoCap.isOpened():
        print(f"[{video_name}] Error: Could not open video file")
        return None
    
    # Get video properties
    fps = int(videoCap.get(cv2.CAP_PROP_FPS))
    total_frames = int(videoCap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # Storage for results
    detection_results = []
    tracked_people = {}
    local_person_count = 0
    frame_number = 0
    
    print(f"[{video_name}] Processing {total_frames} frames at {fps} FPS...")
    processing_start_time = time.time()
    last_progress_time = processing_start_time
    
    while True:
        ret, frame = videoCap.read()
        if not ret:
            break
        
        frame_number += 1
        
        # Process every 10 frames
        if frame_number % 10 != 0:
            continue
        
        # Show progress every 5 seconds
        current_time = time.time()
        if current_time - last_progress_time >= 5.0:
            elapsed = current_time - processing_start_time
            progress = (frame_number / total_frames) * 100
            estimated_total_time = (elapsed / progress) * 100 if progress > 0 else 0
            remaining_time = estimated_total_time - elapsed
            
            print(f"[{video_name}] Progress: {progress:.1f}% - Frame {frame_number}/{total_frames} - "
                  f"Elapsed: {elapsed:.1f}s - ETA: {remaining_time:.1f}s - "
                  f"People found: {local_person_count}")
            last_progress_time = current_time
        
        # Stage 1: Track persons
        results = person_model.track(frame, persist=True, verbose=False)
        
        for result in results:
            if result.boxes is not None and result.boxes.id is not None:
                for box, track_id in zip(result.boxes, result.boxes.id):
                    if box.conf[0] > 0.4 and int(box.cls[0]) == 0:  # class 0 = person
                        track_id = int(track_id)
                        
                        # Skip if we've already processed this person
                        if track_id in tracked_people:
                            continue
                        
                        local_person_count += 1
                        global_person_number = global_person_counter.increment()
                        
                        x1, y1, x2, y2 = map(int, box.xyxy[0])
                        confidence = float(box.conf[0])
                        
                        # Crop person ROI
                        person_roi = frame[y1:y2, x1:x2]
                        
                        # Skip if cropped region is too small
                        if person_roi.shape[0] < 50 or person_roi.shape[1] < 50:
                            continue
                        
                        # Stage 2: Run t-shirt model on cropped person
                        tshirt_results = tshirt_model(person_roi, verbose=False)
                        
                        # Extract t-shirt information
                        tshirt_info = []
                        if tshirt_results[0].boxes is not None:
                            for tshirt_box in tshirt_results[0].boxes:
                                if tshirt_box.conf[0] > 0.3:
                                    tshirt_conf = float(tshirt_box.conf[0])
                                    if hasattr(tshirt_results[0], 'names') and tshirt_results[0].names:
                                        class_id = int(tshirt_box.cls[0])
                                        tshirt_class = tshirt_results[0].names.get(class_id, f"class_{class_id}")
                                    else:
                                        tshirt_class = f"tshirt_class_{int(tshirt_box.cls[0])}"
                                    
                                    tshirt_info.append({
                                        "class": tshirt_class,
                                        "confidence": tshirt_conf
                                    })
                        
                        # Save person image
                        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]  # Include milliseconds
                        person_filename = f"person_global_{global_person_number:04d}_track_{track_id:04d}_frame_{frame_number}_{timestamp}.jpg"
                        person_path = os.path.join(video_output_dir, person_filename)
                        cv2.imwrite(person_path, person_roi)
                        
                        # Save annotated version
                        annotated_filename = None
                        if tshirt_results[0].plot() is not None:
                            annotated_roi = tshirt_results[0].plot()
                            annotated_filename = f"annotated_global_{global_person_number:04d}_track_{track_id:04d}_frame_{frame_number}_{timestamp}.jpg"
                            annotated_path = os.path.join(video_output_dir, annotated_filename)
                            cv2.imwrite(annotated_path, annotated_roi)
                        
                        # Store detection result
                        detection_data = {
                            "video_file": video_name,
                            "global_person_number": global_person_number,
                            "track_id": track_id,
                            "local_person_number": local_person_count,
                            "first_detected_frame": frame_number,
                            "timestamp": timestamp,
                            "person_confidence": confidence,
                            "bounding_box": {
                                "x1": x1, "y1": y1, "x2": x2, "y2": y2
                            },
                            "tshirt_detections": tshirt_info,
                            "person_image": person_filename,
                            "annotated_image": annotated_filename
                        }
                        
                        tracked_people[track_id] = detection_data
                        detection_results.append(detection_data)
                        
                        print(f"[{video_name}] New person: Global #{global_person_number}, Track ID {track_id}, "
                              f"Local #{local_person_count}, T-shirts: {len(tshirt_info)}")
    
    videoCap.release()
    
    # Calculate processing time
    total_processing_time = time.time() - processing_start_time
    processing_end_time = datetime.now()
    
    # Create result summary for this video
    result_summary = {
        "video_file": video_path,
        "video_name": video_name,
        "processing_info": {
            "model_load_time_seconds": round(model_load_time, 2),
            "video_processing_time_seconds": round(total_processing_time, 2),
            "total_time_seconds": round(model_load_time + total_processing_time, 2),
            "processing_start": processing_start_time,
            "processing_end": processing_end_time.isoformat()
        },
        "total_unique_people_detected": local_person_count,
        "total_frames_processed": frame_number,
        "tracking_ids_detected": list(tracked_people.keys()),
        "detection_results": detection_results,
        "output_directory": video_output_dir
    }
    
    # Save individual video results
    results_filename = os.path.join(video_output_dir, f"results_{video_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
    with open(results_filename, 'w') as f:
        json.dump(result_summary, f, indent=2)
    
    print(f"[{video_name}] Complete! Processing time: {total_processing_time:.2f}s, "
          f"People detected: {local_person_count}, Results: {results_filename}")
    
    return result_summary

def process_multiple_videos(video_paths, max_workers=None, output_base_dir="detected_people"):
    """Process multiple videos concurrently"""
    # Create main output directory
    os.makedirs(output_base_dir, exist_ok=True)
    
    # Determine optimal number of workers
    if max_workers is None:
        # Use number of CPU cores, but limit to avoid overwhelming the system
        max_workers = min(len(video_paths), os.cpu_count() or 1, 4)
    
    print(f"Starting concurrent processing of {len(video_paths)} videos with {max_workers} workers...")
    print(f"Videos to process: {[Path(p).name for p in video_paths]}")
    
    overall_start_time = time.time()
    all_results = []
    
    # Process videos concurrently
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all video processing tasks
        future_to_video = {
            executor.submit(process_single_video, video_path, output_base_dir): video_path 
            for video_path in video_paths
        }
        
        # Collect results as they complete
        for future in as_completed(future_to_video):
            video_path = future_to_video[future]
            video_name = Path(video_path).name
            
            try:
                result = future.result()
                if result:
                    all_results.append(result)
                    print(f"✓ [{video_name}] Processing completed successfully")
                else:
                    print(f"✗ [{video_name}] Processing failed")
            except Exception as exc:
                print(f"✗ [{video_name}] Generated an exception: {exc}")
    
    # Calculate overall statistics
    overall_processing_time = time.time() - overall_start_time
    total_people_detected = sum(result['total_unique_people_detected'] for result in all_results)
    
    # Create combined results summary
    combined_results = {
        "processing_summary": {
            "total_videos_processed": len(all_results),
            "total_videos_requested": len(video_paths),
            "max_workers_used": max_workers,
            "overall_processing_time_seconds": round(overall_processing_time, 2),
            "processing_timestamp": datetime.now().isoformat(),
            "total_people_detected_across_all_videos": total_people_detected
        },
        "individual_video_results": all_results
    }
    
    # Save combined results
    combined_results_filename = f"combined_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(combined_results_filename, 'w') as f:
        json.dump(combined_results, f, indent=2)
    
    # Print summary
    print("\n" + "="*60)
    print("PROCESSING COMPLETE!")
    print("="*60)
    print(f"Total videos processed: {len(all_results)}/{len(video_paths)}")
    print(f"Overall processing time: {overall_processing_time:.2f} seconds")
    print(f"Total unique people detected: {total_people_detected}")
    print(f"Results saved to: {combined_results_filename}")
    print(f"Individual results saved in: {output_base_dir}")
    
    return combined_results

# Main execution
if __name__ == "__main__":
    # Find all video files in current directory (you can modify this)
    video_extensions = ['*.mp4', '*.avi', '*.mov', '*.mkv', '*.wmv']
    video_files = ["test.mp4", "cctv_1.mp4", "cctv_2.mp4"]
    for ext in video_extensions:
        video_files.extend(glob.glob(ext))
    
    # Or manually specify video files:
    # video_files = ['cctv_1.mp4', 'cctv_2.mp4', 'cctv_3.mp4']
    
    if not video_files:
        print("No video files found! Please check your video files.")
        print("Current directory contents:")
        print([f for f in os.listdir('.') if f.endswith(('.mp4', '.avi', '.mov', '.mkv', '.wmv'))])
    else:
        print(f"Found {len(video_files)} video files: {video_files}")
        
        # Process all videos concurrently
        # You can adjust max_workers based on your system capabilities
        results = process_multiple_videos(
            video_files, 
            max_workers=3,  # Adjust based on your system (CPU cores, RAM, GPU)
            output_base_dir="detected_people_concurrent"
        )