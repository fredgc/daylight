;; Copyright 2024 Google LLC
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;      http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;; compiler commands:
(setq local-command-list
      '(
        ;; If this fails, run
        ;; flutter pub global activate devtools
        ;; still supported?  ("*devtools*" "flutter pub global run devtools")
        ;; ("*web-server*" "flutter run |& clean-ant")
        ("*web-server*" "flutter run --verbose -d web-server --web-port 5000 |& clean-ant")
        ;; ("*emulator*" "cd out; firebase -c ../firebase.json emulators:start")
        ))

(defun reload-web-server ()
  (interactive)
  (save-some-buffers)
  (with-current-buffer "*web-server*"

    (process-send-string "*web-server*" "r")
    ))
(global-set-key (kbd "H-.") 'reload-web-server)
(global-set-key (kbd "s-.") 'reload-web-server)
(global-set-key (kbd "C-M-.") 'reload-web-server)


;; Consider this:
(defun fix-case-statements ()
  (interactive)
  (c-set-offset 'case-label '+)
  )
