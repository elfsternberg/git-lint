; Given a set of command-line arguments, compare that to a mapped
; version of the optlist and return a canonicalized dictionary of all
; the arguments that have been set.  For example "-c" and "--config"
; will both be mapped to "config".

; Given a prefix of one or two dashes and a position in the above
; array, creates a function to map either the short or long option
; to the option name.

(import os sys inspect getopt)

(defn get-script-name []
  (if (getattr sys "frozen" False)
    (let [[(, path name) (os.path.split sys.executable)]]
      (name))
    (let [[prefix (.upper sys.exec_prefix)]
          [names (filter (fn [a] (let [[fname (get a 1)]]
                                   (not (or (.startswith fname "<") (.startswith (.upper fname) prefx))))
                           (.stack inspect)))]
          [name (.pop names)]]
      (name))))

(defn make-options-rationalizer [optlist]
  (let [[short-opt-assoc (make-opt-assoc "-" 0)]
        [long-opt-assoc (make-opt-assoc "--" 1)]
        [fullset 
         (reduce (fn [acc i] (-> (short-opt-assoc acc i)
                                 (long-opt-assoc i))) optlist {})]]
    (fn [acc it] (do (assoc acc (get fullset (get it 0)) (get it 1)) acc))))

(defn make-opt-assoc [prefix pos]
  (fn [acc it] (assoc acc (+ prefix (get it pos)) (get it 1)) acc)) 

(defclass hyopt []
  [[print-help (fn [self]
                 (print (.format (_ "Usage: {} [options] [filenames]") self.name))
                 (for [item optlist] (print (.format " -{:<1}  --{:<12}  {}" (get item 0) (get item 1) (get item 3))))
                 (sys.exit))]
   [print-version (fn [self]
                    (print (.format "{}" self.name self.version))
                    (if (self.copyright)
                      (print self.copyright))
                    (sys.exit))]

   [--init-- (fn [self optlist args &optional [name ""] [copyright ""] [version "0.0.1"]]
           (let [[optstringsshort 
                  (.join "" (map (fn [i] (+ (. i [0]) (cond [(. i [2]) ":"] [true ""]))) optlist))]
                 [optstringslong 
                  (list (map (fn [i] (+ (. i [1]) (cond [(. i [2]) "="] [true ""]))) optlist))]
                 [(, opt arg) 
                  (getopt.getopt (slice args 1) optstringsshort optstringslong)]
                 [rationalize-options (make-options-rationalizer optlist)]]
             (setv self.options (reduce (fn [acc i] (rationalize-options acc i)) opt {}))
             (setv self.name (if name name (get-script-name)))
             (setv self.version version)
             (setv self.copyright copyright))
             None)]])
  

