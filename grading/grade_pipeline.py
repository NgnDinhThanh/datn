import cv2
import numpy as np
import json
from aruco_dict import ARUCO_DICT

# --- Cấu hình chung ---
ARUCO_TYPE = 'DICT_4X4_50'
TEMPLATE_JSON = 'output/answer_sheet_100.json'
INPUT_IMAGE = 'input_images/img3.jpg'
WARPED_IMAGE = 'warped_image.jpg'
OUTPUT_IMAGE = 'graded_result_img3.jpg'

# Ngưỡng pixel tô
MIN_ANSWER_PIXELS = 1200
MIN_ID_PIXELS = {
    'student': 700,
    'quiz': 600,
    'class': 600
}

# Màu vẽ
COLORS = {
    'correct': (0, 255, 0),
    'wrong': (0, 0, 255),
    'highlight': (0, 255, 255),
    'text': (0, 0, 255)
}
FONT = cv2.FONT_HERSHEY_SIMPLEX

# Answer key mẫu (thay bằng của bạn nếu khác)
ANSWER_KEY = {0: 2, 1: 3, 2: 4, 3: 0, 4: 4, 5: 3, 6: 2, 7: 1, 8: 4, 9: 3, 10: 0, 11: 3, 12: 0, 13: 2, 14: 1, 15: 1,
              16: 2, 17: 2, 18: 0, 19: 4, 20: 0, 21: 1, 22: 1, 23: 2, 24: 3,
              25: 0, 26: 0, 27: 3, 28: 4, 29: 4, 30: 4, 31: 2, 32: 0, 33: 4, 34: 4, 35: 1, 36: 3, 37: 2, 38: 0, 39: 0,
              40: 3, 41: 0, 42: 0, 43: 3, 44: 2, 45: 1, 46: 0, 47: 2, 48: 2, 49: 1,
              50: 2, 51: 2, 52: 2, 53: 2, 54: 4, 55: 4, 56: 2, 57: 4, 58: 3, 59: 4, 60: 0, 61: 3, 62: 1, 63: 3, 64: 1,
              65: 3, 66: 2, 67: 4, 68: 0, 69: 1, 70: 3, 71: 0, 72: 3, 73: 1, 74: 1,
              75: 1, 76: 4, 77: 4, 78: 2, 79: 0, 80: 4, 81: 0, 82: 0, 83: 3, 84: 1, 85: 1, 86: 2, 87: 3, 88: 0, 89: 0,
              90: 1, 91: 1, 92: 2, 93: 0, 94: 3, 95: 0, 96: 3, 97: 1, 98: 2, 99: 2}


def load_data(img_path, json_path):
    img = cv2.imread(img_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    with open(json_path, 'r') as f:
        data = json.load(f)
    return img, gray, data


def detect_aruco(gray, aruco_type):
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(blurred)
    arucoDict = cv2.aruco.getPredefinedDictionary(ARUCO_DICT[aruco_type])
    arucoParams = cv2.aruco.DetectorParameters()
    arucoDetector = cv2.aruco.ArucoDetector(arucoDict, arucoParams)
    (corners, ids, _) = arucoDetector.detectMarkers(gray)
    positions = []
    if ids is not None:
        ids = ids.flatten()
        for markerCorner, markerID in zip(corners, ids):
            corners_reshaped = markerCorner.reshape((4, 2))
            (topLeft, topRight, bottomRight, bottomLeft) = corners_reshaped
            cX = int((topLeft[0] + bottomRight[0]) / 2.0)
            cY = int((topLeft[1] + bottomRight[1]) / 2.0)

            positions.append({'id': int(markerID), 'position': [cX, cY]})
    return positions


def warp_to_template(img, detected, template_markers):
    input_points, template_points = [], []

    for marker in template_markers:
        marker_id = marker["id"]

        matching_marker = next((m for m in detected if m["id"] == marker_id), None)
        if matching_marker:
            input_points.append(matching_marker["position"])
            template_points.append(marker["position"])

    input_points = np.array(input_points, dtype=np.float32)
    template_points = np.array(template_points, dtype=np.float32)

    H, _ = cv2.findHomography(input_points, template_points, cv2.RANSAC)
    (w, h) = (2481, 3508)
    warped = cv2.warpPerspective(img, H, (w, h))
    cv2.imwrite(WARPED_IMAGE, warped)
    return warped


def verify_warp(image, data):
    # Vẽ marker
    for m in data['aruco_marker']:
        cx, cy = m['position']
        r = m.get('size', 50) // 2
        pts = [(cx - r, cy - r), (cx + r, cy - r), (cx + r, cy + r), (cx - r, cy + r)]
        for i in range(4):
            cv2.line(image, pts[i], pts[(i + 1) % 4], COLORS['wrong'], 2)
        cv2.putText(image, str(m['id']), (cx - 10, cy - 10), FONT, 0.5, COLORS['wrong'], 1)
    # Vẽ vùng info, student, quiz, class, answer
    colors = {
        'info_section': (0, 255, 0),
        'student_id_section': (255, 0, 0),
        'quiz_id_section': (0, 0, 255),
        'class_id_section': (0, 255, 255),
        'answer_area': (255, 0, 255)
    }
    for name, clr in colors.items():
        x, y, w, h = data[name]['position']
        cv2.rectangle(image, (x, y), (x + w, y + h), clr, 2)
        cv2.putText(image, name, (x, y - 5), FONT, 0.5, clr, 1)
    return image


def bounding_box(bubbles, shape):
    xs = [b['position'][0] for b in bubbles]
    ys = [b['position'][1] for b in bubbles]
    rs = [b['radius'] for b in bubbles]
    x1 = max(int(min(xs) - max(rs)), 0)
    x2 = min(int(max(xs) + max(rs)), shape[1])
    y1 = max(int(min(ys) - max(rs)), 0)
    y2 = min(int(max(ys) + max(rs)), shape[0])
    return x1, y1, x2, y2


def threshold_region(gray, box):
    x_min, y_min, x_max, y_max = box
    roi = gray[y_min:y_max, x_min:x_max]
    _, thresh = cv2.threshold(roi, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)
    return thresh, (x_min, y_min)


def detect_marked(bubbles, thresh, min_pixels):
    marked = []
    for idx, b in enumerate(bubbles):
        x0 = int(b["position"][0] - box[0])
        y0 = int(b["position"][1] - box[1])
        r = int(b["radius"])
        mask = np.zeros_like(thresh)
        cv2.circle(mask, (x0, y0), r, 255, -1)
        cnt = cv2.countNonZero(cv2.bitwise_and(thresh, thresh, mask=mask))
        if cnt >= min_pixels:
            marked.append((cnt, idx))
    return marked


def draw_answer_circles(img, bubbles, selected, correct_idx):
    if len(selected) == 0:
        x, y = map(int, bubbles[correct_idx]['position'])
        r = int(bubbles[correct_idx]['radius'])
        cv2.circle(img, (x,y), r, COLORS['highlight'], 3)

    if len(selected) == 1:
        sel = selected[0]
        x, y = map(int, bubbles[sel]['position'])
        r = int(bubbles[sel]['radius'])
        if sel == correct_idx:
            cv2.circle(img, (x, y), r, COLORS['correct'], 3)
        else:
            cv2.circle(img, (x, y), r, COLORS['wrong'], 3)

            x2, y2 = map(int, bubbles[correct_idx]['position'])
            r2 = int(bubbles[correct_idx]['radius'])
            cv2.circle(img,(x2, y2), r2, COLORS['highlight'], 3)

    if correct_idx in selected:
        x, y = map(int, bubbles[correct_idx]['position'])
        r = int(bubbles[correct_idx]['radius'])
        cv2.circle(img, (x, y), r, COLORS['correct'], 3)
        for sel in selected:
            if sel == correct_idx: continue
            x, y = map(int, bubbles[sel]['position'])
            r = int(bubbles[sel]['radius'])
            cv2.circle(img, (x, y), r, COLORS['wrong'], 3)

    else:
        x2, y2 = map(int, bubbles[correct_idx]['position'])
        r2 = int(bubbles[correct_idx]['radius'])
        cv2.circle(img, (x2, y2), r2, COLORS['highlight'], 3)
        for sel in selected:
            x, y = map(int, bubbles[sel]['position'])
            r = int(bubbles[sel]['radius'])
            cv2.circle(img, (x, y), r, COLORS['wrong'], 3)


def grade_answers(img, gray, questions, answer_key):
    correct = 0
    for q in questions:
        q_idx = q['question'] - 1
        bubbles = q['bubbles']
        global box
        box = bounding_box(bubbles, img.shape)
        thresh, _ = threshold_region(gray, box)

        marked = []
        for cnt, idx in detect_marked(bubbles, thresh, MIN_ANSWER_PIXELS):
            marked.append(idx)

        selected, status = [], 'skipped'
        if len(marked) == 1:
            selected = marked
        elif len(marked) > 1:
            selected = marked
            status = 'multiple'

        correct_idx = answer_key[q_idx]
        if status == 'skipped':
            status = 'correct' if not marked else 'wrong'
            if marked and marked[0] == correct_idx:
                correct += 1
        elif status == 'correct':
            correct += 1

        draw_answer_circles(img, bubbles, selected, correct_idx)
    return correct


def read_id_section(img, gray, sec, label):
    digits = []
    for col in sec['columns']:
        box, origin = bounding_box(col['bubbles'], gray.shape), None
        thresh, origin = threshold_region(gray, box)
        best = None
        for b in col['bubbles']:
            x = int(b['position'][0] - origin[0])
            y = int(b['position'][1] - origin[1])
            r = int(b['radius'])
            mask = np.zeros_like(thresh, dtype=np.uint8)
            cv2.circle(mask, (x, y), r, 255, -1)
            cnt = cv2.countNonZero(cv2.bitwise_and(thresh, thresh, mask=mask))
            if cnt >= MIN_ID_PIXELS[label] and (best is None or cnt > best[0]):
                best = (cnt, b['value'], b)
        if best is None:
            return None
        _, val, bub = best
        digits.append(val)
        # highlight bubble chọn
        px, py, pr = map(int, bub['position'] + [bub['radius']])
        cv2.circle(img, (px, py), pr, COLORS['correct'], 2)
    return digits


def main():
    # 1. Load
    orig, gray, data = load_data(INPUT_IMAGE, TEMPLATE_JSON)
    # 2. Detect + Warp
    det = detect_aruco(gray, ARUCO_TYPE)
    warped = warp_to_template(orig, det, data['aruco_marker'])
    # cv2.imwrite(WARPED_IMAGE, warped)
    # 3. Verify (tuỳ chọn: lưu file verify)
    ver = verify_warp(warped.copy(), data)
    cv2.imwrite('verify_warp.jpg', ver)
    # 4. Grade & Read IDs
    w_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
    score = grade_answers(warped, w_gray, data['answer_area']['questions'], ANSWER_KEY)
    stu_id = read_id_section(warped, w_gray, data['student_id_section'], 'student')
    quiz_id = read_id_section(warped, w_gray, data['quiz_id_section'], 'quiz')
    cls_id = read_id_section(warped, w_gray, data['class_id_section'], 'class')
    # 5. Overlay text
    lines = [f"Score: {score}/{len(ANSWER_KEY)} = {score / len(ANSWER_KEY) * 100:.2f}%"]
    if stu_id:  lines.append("Student ID: " + ''.join(map(str, stu_id)))
    if quiz_id: lines.append("Quiz ID:    " + ''.join(map(str, quiz_id)))
    if cls_id:  lines.append("Class ID:   " + ''.join(map(str, cls_id)))
    for i, txt in enumerate(lines):
        cv2.putText(warped, txt, (10, 30 + i * 30), FONT, 0.8, COLORS['text'], 2)
    # 6. Save & Show
    cv2.imwrite(OUTPUT_IMAGE, warped)
    cv2.imshow("Result", warped)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


main()