/** <title>NSAffineTransform.m</title>

   <abstract>
   This class provides a way to perform affine transforms.  It provides 
   a matrix for transforming from one coordinate system to another.
   </abstract>
   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: August 1997
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: March 1999
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#include "config.h"
#include <math.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>

#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSBezierPath.h"
#include "AppKit/PSOperators.h"

/* Private definitions */
#define A matrix.m11
#define B matrix.m12
#define C matrix.m21
#define D matrix.m22
#define TX matrix.tX
#define TY matrix.tY

/* A Postscript matrix looks like this:

  /  a  b  0 \
  |  c  d  0 |
  \ tx ty  1 /

 */

static const float pi = 3.1415926535897932384626434;

/* Quick function to multiply two coordinate matrices. C = AB */
static inline NSAffineTransformStruct 
matrix_multiply (NSAffineTransformStruct MA, NSAffineTransformStruct MB)
{
  NSAffineTransformStruct MC;
  MC.m11 = MA.m11 * MB.m11 + MA.m12 * MB.m21;
  MC.m12 = MA.m11 * MB.m12 + MA.m12 * MB.m22;
  MC.m21 = MA.m21 * MB.m11 + MA.m22 * MB.m21;
  MC.m22 = MA.m21 * MB.m12 + MA.m22 * MB.m22;
  MC.tX  = MA.tX * MB.m11 + MA.tY * MB.m21 + MB.tX;
  MC.tY  = MA.tX * MB.m12 + MA.tY * MB.m22 + MB.tY;
  return MC;
}

@implementation NSAffineTransform

static NSAffineTransformStruct identityTransform = {
   1.0, 0.0, 0.0, 1.0, 0.0, 0.0
};

/**
 * Return an autoreleased instance of this class.
 */
+ (NSAffineTransform*) transform
{
  NSAffineTransform	*t;

  t = (NSAffineTransform*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  t->matrix = identityTransform;
  return AUTORELEASE(t);
}

/**
 * Return an autoreleased instance of this class.
 */
+ (id) new
{
  NSAffineTransform	*t;

  t = (NSAffineTransform*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  t->matrix = identityTransform;
  return t;
}

/**
 * Appends the transform matrix to the receiver.  This is done by performing a
 * matrix multiplication of the receiver with aTransform so that aTransform
 * is the first transform applied to the user coordinate. The new
 * matrix then replaces the receiver's matrix.
 */
- (void) appendTransform: (NSAffineTransform*)aTransform
{
  matrix = matrix_multiply(matrix, aTransform->matrix);
}

/**
 * Concatenates the receiver's matrix with the one in the current graphics 
 * context.
 */
- (void) concat
{
  float m[6];
  m[0] = matrix.m11;
  m[1] = matrix.m12;
  m[2] = matrix.m21;
  m[3] = matrix.m22;
  m[4] = matrix.tX;
  m[5] = matrix.tY;
  PSconcat(m);
}

/**
 * Initialize the transformation matrix instance to the identity matrix.
 * The identity matrix transforms a point to itself.
 */ 
- (id) init
{
  matrix = identityTransform;
  return self;
}

/**
 * Initialize the receiever's instance with the instance represented 
 * by aTransform. 
 */
- (id) initWithTransform: (NSAffineTransform*)aTransform
{
  matrix = aTransform->matrix;
  return self;
}

/**
 * Calculates the inverse of the receiver's matrix and replaces the 
 * receiever's matrix with it.
 */
- (void) invert
{
  float newA, newB, newC, newD, newTX, newTY;
  float det;

  det = A * D - B * C;
  if (det == 0)
    {
      NSLog (@"error: determinant of matrix is 0!");
      return;
    }

  newA = D / det;
  newB = -B / det;
  newC = -C / det;
  newD = A / det;
  newTX = (-D * TX + C * TY) / det;
  newTY = (B * TX - A * TY) / det;

  NSDebugLLog(@"NSAffineTransform",
	@"inverse of matrix ((%f, %f) (%f, %f) (%f, %f))\n"
	@"is ((%f, %f) (%f, %f) (%f, %f))",
	A, B, C, D, TX, TY,
	newA, newB, newC, newD, newTX, newTY);

  A = newA; B = newB;
  C = newC; D = newD;
  TX = newTX; TY = newTY;
}

/**
 * Prepends the transform matrix to the receiver.  This is done by performing a
 * matrix multiplication of the receiver with aTransform so that aTransform
 * is the last transform applied to the user coordinate. The new
 * matrix then replaces the receiver's matrix.
 */
- (void) prependTransform: (NSAffineTransform*)aTransform
{
  matrix = matrix_multiply(aTransform->matrix, matrix);
}

/**
 * Applies the rotation specified by angle in degrees.   Points transformed
 * with the transformation matrix of the receiver are rotated counter-clockwise 
 * by the number of degrees specified by angle.
 */
- (void) rotateByDegrees: (float)angle
{
  [self rotateByRadians: pi * angle / 180];
}

/**
 * Applies the rotation specified by angle in radians.   Points transformed
 * with the transformation matrix of the receiver are rotated counter-clockwise 
 * by the number of radians specified by angle.
 */
- (void) rotateByRadians: (float)angleRad
{
  float sine = sin (angleRad);
  float cosine = cos (angleRad);
  NSAffineTransformStruct rotm;
  rotm.m11 = cosine; rotm.m12 = sine; rotm.m21 = -sine; rotm.m22 = cosine;
  rotm.tX = rotm.tY = 0;
  matrix = matrix_multiply(rotm, matrix);
}

/**
 * Scales the transformation matrix of the reciever by the factor specified
 * by scale.  
 */
- (void) scaleBy: (float)scale
{
  NSAffineTransformStruct scam = identityTransform;
  scam.m11 = scale; scam.m22 = scale;
  matrix = matrix_multiply(scam, matrix);
}

/**
 * Scales the X axis of the receiver's transformation matrix 
 * by scaleX and the Y axis of the transformation matrix by scaleY.
 */
- (void) scaleXBy: (float)scaleX yBy: (float)scaleY
{
  NSAffineTransformStruct scam = identityTransform;
  scam.m11 = scaleX; scam.m22 = scaleY;
  matrix = matrix_multiply(scam, matrix);
}

/**
 * Get the currently active graphics context's transformation 
 * matrix and set it into the receiver.
 */

- (void) set
{
  GSSetCTM(GSCurrentContext(), self);
}

/**
 * <p>
 * Sets the structure which represents the matrix of the reciever. 
 * The struct is of the form:</p>
 * <p>{m11, m12, m21, m22, tX, tY}</p>
 */
- (void) setTransformStruct: (NSAffineTransformStruct)val
{
  matrix = val;
}

/**
 * <p>
 * Applies the receiver's transformation matrix to each point in 
 * the bezier path, then returns the result.  The original bezier 
 * path is not modified.
 * </p>
 */
- (NSBezierPath*) transformBezierPath: (NSBezierPath*)aPath
{
  NSBezierPath *path = [aPath copy];

  [path transformUsingAffineTransform: self];
  return AUTORELEASE(path);
}

/**
 * Transforms a single point based on the transformation matrix.
 * Returns the resulting point.
 */
- (NSPoint) transformPoint: (NSPoint)aPoint
{
  NSPoint new;

  new.x = A * aPoint.x + C * aPoint.y + TX;
  new.y = B * aPoint.x + D * aPoint.y + TY;

  return new;
}

/**
 * Transforms the NSSize represented by aSize using the reciever's 
 * transformation matrix.  Returns the resulting NSSize.
 */
- (NSSize) transformSize: (NSSize)aSize
{
  NSSize new;

  new.width = A * aSize.width + C * aSize.height;
  if (new.width < 0)
    new.width = - new.width;
  new.height = B * aSize.width + D * aSize.height;
  if (new.height < 0)
    new.height = - new.height;

  return new;
}

/**
 * <p>
 * Returns the <code>NSAffineTransformStruct</code> structure 
 * which represents the matrix of the reciever. 
 * The struct is of the form:</p>
 * <p>{m11, m12, m21, m22, tX, tY}</p>
 */
- (NSAffineTransformStruct) transformStruct
{
  return matrix;
}

/**
 * Applies the translation specified by tranX and tranY to the receiver's matrix.
 * Points transformed by the reciever's matrix after this operation will 
 * be shifted in position based on the specified translation.
 */
- (void) translateXBy: (float)tranX  yBy: (float)tranY
{
  NSAffineTransformStruct tranm = identityTransform;
  tranm.tX = tranX;
  tranm.tY = tranY;
  matrix = matrix_multiply(tranm, matrix);
}

- (id) copyWithZone: (NSZone*)zone
{
  return NSCopyObject(self, 0, zone);
}

- (BOOL) isEqual: (id)anObject
{
  if ([anObject class] == isa)
    {
      NSAffineTransform	*o = anObject;

      if (A == o->A && B == o->B && C == o->C
	&& D == o->D && TX == o->TX && TY == o->TY)
	return YES;
    }
  return NO;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  float replace[6];
    
  [aCoder decodeArrayOfObjCType: @encode(float)
	  count: 6
	  at: replace];
  [self setMatrix: replace];

  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  float replace[6];
    
  [self getMatrix: replace];
  [aCoder encodeArrayOfObjCType: @encode(float)
	  count: 6
	  at: replace];
}

@end /* NSAffineTransform */

@implementation NSAffineTransform (GNUstep)

- (void) scaleTo: (float)sx : (float)sy
{
  /* If it's rotated.  */
  if (B != 0  ||  C != 0)
    {
      float angle = [self rotationAngle];

      A = sx; B = 0;
      C = 0; D = sy;

      [self rotateByDegrees: angle];
    }
  else
    {
      A = sx; B = 0;
      C = 0; D = sy;
    }
}

- (void) translateToPoint: (NSPoint)point
{
  float newTX, newTY;

  newTX = point.x * A + point.y * C + TX;
  newTY = point.x * B + point.y * D + TY;
  TX = newTX;
  TY = newTY;
}


- (void) makeIdentityMatrix
{
  matrix = identityTransform;
}

- (void) setFrameOrigin: (NSPoint)point
{
  float dx = point.x - TX;
  float dy = point.y - TY;
  [self translateToPoint: NSMakePoint(dx, dy)];
}

- (void) setFrameRotation: (float)angle
{
  [self rotateByDegrees: angle - [self rotationAngle]];
}

- (float) rotationAngle
{
  float rotationAngle = atan2(-C, A);
  rotationAngle *= 180.0 / pi;
  if (rotationAngle < 0.0)
    rotationAngle += 360.0;

  return rotationAngle;
}

- (void) concatenateWith: (NSAffineTransform*)anotherMatrix
{
  [self prependTransform: anotherMatrix];
}

- (void) concatenateWithMatrix: (const float[6])anotherMatrix
{
  NSAffineTransformStruct amat;
  amat.m11 = anotherMatrix[0];
  amat.m12 = anotherMatrix[1];
  amat.m21 = anotherMatrix[2];
  amat.m22 = anotherMatrix[3];
  amat.tX  = anotherMatrix[4];
  amat.tY  = anotherMatrix[5];
  matrix = matrix_multiply(amat, matrix);
}

- (void)inverse
{
  [self invert];
}

- (BOOL) isRotated
{
  if (B == 0  &&  C == 0)
    {
      return NO;
    }
  else
    {
      return YES;
    }
}

- (void) boundingRectFor: (NSRect)rect result: (NSRect*)newRect
{
  /* Shortcuts of the usual rect values */
  float x = rect.origin.x;
  float y = rect.origin.y;
  float width = rect.size.width;
  float height = rect.size.height;
  float xc[3];
  float yc[3];
  float min_x;
  float max_x;
  float min_y;
  float max_y;
  int i;

  max_x = A * x + C * y + TX;
  max_y = B * x + D * y + TY;
  xc[0] = max_x + A * width;
  yc[0] = max_y + B * width;
  xc[1] = max_x + C * height;
  yc[1] = max_y + D * height;
  xc[2] = max_x + A * width + C * height;
  yc[2] = max_y + B * width + D * height;
  
  min_x = max_x;
  min_y = max_y;
  
  for (i = 0; i < 3; i++) 
    {
      if (xc[i] < min_x)
	min_x = xc[i];
      if (xc[i] > max_x)
	max_x = xc[i];

      if (yc[i] < min_y)
	 min_y = yc[i];
      if (yc[i] > max_y)
	max_y = yc[i];
    }

  newRect->origin.x = min_x;
  newRect->origin.y = min_y;
  newRect->size.width = max_x -min_x;
  newRect->size.height = max_y -min_y;
}

- (NSPoint) pointInMatrixSpace: (NSPoint)point
{
  NSPoint new;

  new.x = A * point.x + C * point.y + TX;
  new.y = B * point.x + D * point.y + TY;

  return new;
}

- (NSPoint) deltaPointInMatrixSpace: (NSPoint)point
{
  NSPoint new;

  new.x = A * point.x + C * point.y;
  new.y = B * point.x + D * point.y;

  return new;
}

- (NSSize) sizeInMatrixSpace: (NSSize)size
{
  NSSize new;

  new.width = A * size.width + C * size.height;
  if (new.width < 0)
    new.width = - new.width;
  new.height = B * size.width + D * size.height;
  if (new.height < 0)
    new.height = - new.height;

  return new;
}

- (NSRect) rectInMatrixSpace: (NSRect)rect
{
  NSRect new;

  new.origin.x = A * rect.origin.x + C * rect.origin.y + TX;
  new.size.width = A * rect.size.width + C * rect.size.height;
  if (new.size.width < 0)
    {
      new.origin.x += new.size.width;
      new.size.width *= -1;
    }

  new.origin.y = B * rect.origin.x + D * rect.origin.y + TY;
  new.size.height = B * rect.size.width + D * rect.size.height;
  if (new.size.height < 0)
    {
      new.origin.y += new.size.height;
      new.size.height *= -1;
    }

  return new;
}

- (NSString*) description
{
  return [NSString stringWithFormat:
		@"NSAffineTransform ((%f, %f) (%f, %f) (%f, %f))",
				    A, B, C, D, TX, TY];
}

- (void) setMatrix: (const float[6])replace
{
  matrix.m11 = replace[0];
  matrix.m12 = replace[1];
  matrix.m21 = replace[2];
  matrix.m22 = replace[3];
  matrix.tX = replace[4];
  matrix.tY = replace[5];
}

- (void) getMatrix: (float[6])replace
{
  replace[0] = matrix.m11;
  replace[1] = matrix.m12;
  replace[2] = matrix.m21;
  replace[3] = matrix.m22;
  replace[4] = matrix.tX;
  replace[5] = matrix.tY;
}

- (void) takeMatrixFromTransform: (NSAffineTransform *)aTransform
{
  matrix.m11 = aTransform->matrix.m11;
  matrix.m12 = aTransform->matrix.m12;
  matrix.m21 = aTransform->matrix.m21;
  matrix.m22 = aTransform->matrix.m22;
  matrix.tX = aTransform->matrix.tX;
  matrix.tY = aTransform->matrix.tY;
}


@end /* NSAffineTransform (GNUstep) */

