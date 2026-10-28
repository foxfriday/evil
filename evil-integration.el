;;; evil-integration.el --- Integrate Evil with other modules -*- lexical-binding: t -*-

;; Author: Vegard Øye <vegard_oye at hotmail.com>
;; Maintainer: Vegard Øye <vegard_oye at hotmail.com>

;; Version: 1.15.0

;;
;; This file is NOT part of GNU Emacs.

;;; License:

;; This file is part of Evil.
;;
;; Evil is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Evil is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Evil.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This provides evil integration for various emacs modes.
;; Additional keybindings (or default state) should go into evil-keybindings.el.

;;; Code:

(require 'evil-maps)
(require 'evil-core)
(require 'evil-macros)
(require 'evil-types)
(require 'evil-repeat)

;;; Evilize some commands

;; unbound keys should be ignored
(evil-declare-ignore-repeat 'undefined)

(mapc #'(lambda (cmd)
          (evil-set-command-property cmd :keep-visual t)
          (evil-declare-not-repeat cmd))
      '(digit-argument
        negative-argument
        universal-argument
        universal-argument-minus
        universal-argument-more
        universal-argument-other-key))
(mapc #'evil-declare-not-repeat
      '(what-cursor-position))
(mapc #'evil-declare-change-repeat
      '(dabbrev-expand
        hippie-expand
        quoted-insert))
(mapc #'evil-declare-abort-repeat
      '(balance-windows
        eval-expression
        execute-extended-command
        exit-minibuffer
        compile
        delete-window
        delete-other-windows
        find-file-at-point
        ffap-other-window
        recompile
        redo
        save-buffer
        split-window
        split-window-horizontally
        split-window-vertically
        undo
        undo-tree-redo
        undo-tree-undo))

(evil-set-type #'previous-line 'line)
(evil-set-type #'next-line 'line)

(dolist (cmd '(keyboard-quit keyboard-escape-quit))
  (evil-set-command-property cmd :suppress-operator t))

;;; Mouse
(evil-declare-insert-at-point-repeat 'mouse-yank-primary)
(evil-declare-insert-at-point-repeat 'mouse-yank-secondary)

;;; key-binding

;; Calling `keyboard-quit' should cancel repeat
(advice-add 'keyboard-quit :before #'evil-repeat-abort)

(add-hook 'wdired-mode-hook #'evil-change-to-initial-state)
(advice-add 'wdired-change-to-dired-mode :after
            #'evil--change-to-initial-state-with-msg)
(defun evil--change-to-initial-state-with-msg (&rest _)
  (evil-change-to-initial-state nil t))

;;; Parentheses

(evil--advice-add 'show-paren-function :around #'evil--match-paren-in-normal-state)
(defun evil--match-paren-in-normal-state (orig-fun &rest args)
  "Match parentheses in Normal state."
  (if (or (not evil-local-mode)
          (eq (not (memq 'not evil-highlight-closing-paren-at-point-states))
              (not (memq evil-state evil-highlight-closing-paren-at-point-states))))
      (apply orig-fun args)
    (let* ((orig-spdf show-paren-data-function)
           (show-paren-data-function
            (lambda ()
              (let ((pos (point)) narrow)
                (setq
                 pos (cl-dotimes (i (1+ (* 2 evil-show-paren-range)))
                       (setq pos (+ pos (if (cl-evenp i) i (- i))))
                       (pcase (syntax-class (syntax-after pos))
                         (4 (setq narrow pos) (cl-return pos))
                         (5 (cl-return (1+ pos))))))
                (when pos
                  (save-excursion
                    (goto-char pos)
                    (save-restriction
                      (when narrow (narrow-to-region narrow (point-max)))
                      (funcall orig-spdf))))))))
      (apply orig-fun args))))

;;; Eval last sexp
(defun evil--preceding-sexp (command &rest args)
  "In Normal- or Motion-state, allow last sexp to end at point."
  (save-excursion
    (or evil-move-beyond-eol
        (eolp)
        (not (or (evil-normal-state-p) (evil-motion-state-p)))
        (forward-char))
    (apply command args)))
(advice-add 'elisp--preceding-sexp :around #'evil--preceding-sexp)
(advice-add 'pp-last-sexp          :around #'evil--preceding-sexp)
(advice-add 'lisp-eval-last-sexp   :around #'evil--preceding-sexp)

;;; Show key
(advice-add 'quail-show-key :around #'evil--in-emacs-state)
(advice-add 'describe-char  :around #'evil--in-emacs-state)
(defun evil--in-emacs-state (orig-fun &rest args)
  "Temporarily enter Emacs-state and apply ORIG-FUN to ARGS."
  (if evil-local-mode
      (evil-with-state emacs (apply orig-fun args))
    (apply orig-fun args)))

;;; abbrev.el
(defun evil-maybe-expand-abbrev ()
  (when (and abbrev-mode evil-want-abbrev-expand-on-insert-exit)
    (expand-abbrev)))

(eval-after-load 'abbrev
  '(add-hook 'evil-insert-state-exit-hook #'evil-maybe-expand-abbrev))

;;; ElDoc
(eval-after-load 'eldoc
  '(when (fboundp 'eldoc-add-command-completions)
     (eldoc-add-command-completions "evil-window-")))

;;; XRef
(eval-after-load 'xref
  '(progn
     (evil-set-command-property 'xref-find-definitions :jump t)
     (evil-set-command-property 'xref-find-references :jump t)))

(provide 'evil-integration)

;;; evil-integration.el ends here
